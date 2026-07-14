Function Get-AzDoArtifactFeedPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoArtifactFeedPermission] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $getResult = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null; reason = $null }

    # Resolve the feed — try cache first, fall back to live API.
    $feedCache = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Type 'LiveArtifactFeeds'
    if (-not $feedCache)
    {
        $apiUri = 'https://feeds.dev.azure.com/{0}/' -f $OrganizationName
        try
        {
            $feedCache = List-DevOpsArtifactFeeds -ApiUri $apiUri -ProjectName $ProjectName |
                Where-Object { $_.name -eq $FeedName } | Select-Object -First 1
        } catch { Write-Verbose "[Get-AzDoArtifactFeedPermission] Project-scope list failed: $_" }

        if (-not $feedCache)
        {
            try
            {
                $feedCache = List-DevOpsArtifactFeeds -ApiUri $apiUri |
                    Where-Object { $_.name -eq $FeedName } | Select-Object -First 1
            } catch { Write-Verbose "[Get-AzDoArtifactFeedPermission] Org-scope list failed: $_" }
        }

        if ($feedCache)
        {
            Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Value $feedCache -Type 'LiveArtifactFeeds'
        }
    }

    if (-not $feedCache)
    {
        Write-Warning "[Get-AzDoArtifactFeedPermission] Feed '$FeedName' not found in project '$ProjectName'."
        $getResult.status = [DSCGetSummaryState]::NotFound
        $getResult.reason = "Feed '$FeedName' not found."
        return $getResult
    }

    $getResult.Ensure    = [Ensure]::Present
    $getResult.feedCache = $feedCache

    # Get live permissions for this feed (explicit only — filter out inherited).
    $apiUri     = 'https://feeds.dev.azure.com/{0}/' -f $OrganizationName
    $livePerms  = @(Get-DevOpsArtifactFeedPermission -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feedCache.id)
    $explicitPerms = @($livePerms | Where-Object { -not $_.isInheritedRole })
    $getResult.livePermissions = $explicitPerms


    # Resolve desired permissions to comparable objects.
    # Use only identityDescriptor (the canonical identity key for Feed Permission API).
    $desiredPerms = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($perm in $Permissions)
    {
        $identityName = $perm.Identity.Replace('[', '').Replace(']', '')
        $identity     = Find-Identity -Name $identityName -OrganizationName $OrganizationName -SearchType 'principalName'
        if (-not $identity)
        {
            Write-Warning "[Get-AzDoArtifactFeedPermission] Identity '$($perm.Identity)' not found."
            continue
        }
        $desiredPerms.Add([PSCustomObject]@{
            role               = $perm.Role.ToLower()
            identityDescriptor = $identity.value.ACLIdentity.descriptor
        })
    }

    $getResult.desiredPermissions = $desiredPerms
    $getResult.propertiesChanged  = $desiredPerms

    # Compare desired vs actual. A desired identity can already be satisfied by a default/inherited
    # entry - e.g. Azure DevOps grants 'Project Collection Valid Users: Reader' on every new feed as
    # an inherited role - and PATCHing that identity to the SAME role it already has by inheritance is
    # a platform no-op (the API never promotes it to an explicit entry), which made this permanently
    # report drift. So match desired roles against the FULL live list (inherited + explicit); only
    # extra EXPLICIT permissions not in the desired set count as something to remove.
    $changed = $false
    foreach ($desired in $desiredPerms)
    {
        $match = $livePerms | Where-Object {
            $_.identityDescriptor -eq $desired.identityDescriptor -and $_.role -eq $desired.role
        }
        if (-not $match) { $changed = $true; break }
    }
    if (-not $changed)
    {
        $desiredDescriptors = @($desiredPerms | ForEach-Object { $_.identityDescriptor })
        $extraExplicit = @($explicitPerms | Where-Object { $_.identityDescriptor -notin $desiredDescriptors })
        if ($extraExplicit.Count -gt 0) { $changed = $true }
    }

    if ($changed)
    {
        $getResult.status = [DSCGetSummaryState]::Changed
        $getResult.reason = "Feed permissions differ from desired state."
    }
    else
    {
        $getResult.status = [DSCGetSummaryState]::Unchanged
        $getResult.reason = "Feed permissions match desired state."
    }

    return $getResult
}
