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
        # A feed name stays reserved while a same-named feed sits in the recycle bin (e.g. left over
        # from a previous run). Purge it from the recycle bin (project and org scope) and retry once.
        if ("$_" -match 'reserved|recycle bin')
        {
            $orgName = Get-AzDoOrganizationName
            $projBin = @(List-DevOpsArtifactFeedRecycleBin -OrganizationName $orgName -ProjectName $ProjectName)
            $orgBin  = @(List-DevOpsArtifactFeedRecycleBin -OrganizationName $orgName)
            $recycled = @()
            $recycled += $projBin | Where-Object { $_.name -eq $FeedName }
            $recycled += $orgBin  | Where-Object { $_.name -eq $FeedName }
            foreach ($rf in $recycled)
            {
                Write-Verbose "[New-DevOpsArtifactFeed] Purging reserved feed '$FeedName' ($($rf.id)) from recycle bin before retry."
                Remove-DevOpsArtifactFeedFromRecycleBin -OrganizationName $orgName -ProjectName $ProjectName -FeedId $rf.id
                Remove-DevOpsArtifactFeedFromRecycleBin -OrganizationName $orgName -FeedId $rf.id
            }

            try   { return Invoke-AzDevOpsApiRestMethod @params }
            catch { Throw "[New-DevOpsArtifactFeed] Failed to create artifact feed '$FeedName' after purging recycle bin: $_" }
        }

        Throw "[New-DevOpsArtifactFeed] Failed to create artifact feed '$FeedName': $_"
    }
}
