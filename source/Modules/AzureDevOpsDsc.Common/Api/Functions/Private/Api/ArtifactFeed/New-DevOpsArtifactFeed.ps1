Function New-DevOpsArtifactFeed
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter()][string]$Description,
        [Parameter()][bool]$HideDeletedPackageVersions = $true,
        [Parameter()][bool]$BadgesEnabled = $false,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri }
    $params = @{
        Uri         = '{0}/_apis/packaging/feeds?api-version={1}' -f $baseUri, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name                        = $FeedName
            description                 = $Description
            hideDeletedPackageVersions  = $HideDeletedPackageVersions
            badgesEnabled               = $BadgesEnabled
        } | ConvertTo-Json
    }
    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        # Feed name conflict (409 or FeedNameAlreadyExistsException). The feed already exists.
        # Try to retrieve it directly by name — list-all may not be available with limited token scope.
        if ("$_" -match '409|Conflict|FeedNameAlreadyExists')
        {
            Write-Verbose "[New-DevOpsArtifactFeed] Feed '$FeedName' conflict (409). Fetching existing feed by name..."
            $getUriParams = @{
                Uri    = '{0}/_apis/packaging/feeds/{1}?api-version={2}' -f $baseUri, $FeedName, $ApiVersion
                Method = 'GET'
            }
            try
            {
                $existing = Invoke-AzDevOpsApiRestMethod @getUriParams
                if ($existing) { return $existing }
            }
            catch { Write-Verbose "[New-DevOpsArtifactFeed] Direct GET by name failed: $_" }

            # Try org-scope direct GET as fallback
            $orgBaseUri = $ApiUri.TrimEnd('/')
            $getOrgParams = @{
                Uri    = '{0}/_apis/packaging/feeds/{1}?api-version={2}' -f $orgBaseUri, $FeedName, $ApiVersion
                Method = 'GET'
            }
            try
            {
                $existing = Invoke-AzDevOpsApiRestMethod @getOrgParams
                if ($existing) { return $existing }
            }
            catch { Write-Verbose "[New-DevOpsArtifactFeed] Org-scope GET by name failed: $_" }

            # Feed may be soft-deleted (recycle bin). Purge and retry.
            Write-Verbose "[New-DevOpsArtifactFeed] Trying recycle bin purge..."
            $orgName = Get-AzDoOrganizationName
            $recycled = @()
            $recycled += @(List-DevOpsArtifactFeedRecycleBin -OrganizationName $orgName -ProjectName $ProjectName) |
                Where-Object { $_.name -eq $FeedName }
            $recycled += @(List-DevOpsArtifactFeedRecycleBin -OrganizationName $orgName) |
                Where-Object { $_.name -eq $FeedName }
            foreach ($rf in $recycled)
            {
                Write-Verbose "[New-DevOpsArtifactFeed] Purging feed '$FeedName' ($($rf.id)) from recycle bin."
                try { Remove-DevOpsArtifactFeedFromRecycleBin -OrganizationName $orgName -ProjectName $ProjectName -FeedId $rf.id } catch {}
                try { Remove-DevOpsArtifactFeedFromRecycleBin -OrganizationName $orgName -FeedId $rf.id } catch {}
            }
            if ($recycled.Count -gt 0)
            {
                try   { return Invoke-AzDevOpsApiRestMethod @params }
                catch { Throw "[New-DevOpsArtifactFeed] Failed to create artifact feed '$FeedName' after recycle bin purge: $_" }
            }

            Throw "[New-DevOpsArtifactFeed] Feed '$FeedName' already exists but cannot be retrieved (409 with no accessible existing feed)."
        }

        Throw "[New-DevOpsArtifactFeed] Failed to create artifact feed '$FeedName': $_"
    }
}
