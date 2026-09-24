<#
.SYNOPSIS
Creates an Azure DevOps branch policy.

.DESCRIPTION
Resolves the project, (optionally) the repository and the policy type, then creates the policy
configuration with a scope built from RepositoryName/BranchName/MatchKind - unless the
configuration already supplied its own 'scope' key inside PolicySettings, which is used verbatim.

RepositoryName empty builds a cross-repository scope (no repositoryId); BranchName empty builds a
repository-wide scope (no refName) - see the AzDoBranchPolicy class help for when each applies.
MatchKind 'Prefix' scopes to every branch whose ref name starts with BranchName rather than to one
branch exactly.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER RepositoryName
The Git repository name. Leave empty for a cross-repository policy scope.

.PARAMETER BranchName
The branch ref name (with or without the 'refs/heads/' prefix), or a branch-name prefix when
MatchKind is 'Prefix'. Leave empty for a repository-wide policy scope.

.PARAMETER PolicyType
The policy type display name or short alias (e.g. 'MinimumReviewerCount').

.PARAMETER PolicyIdentifier
Optional. Not used to build the policy itself - carried through so it is available on
$LookupResult for the round-trip Get() that follows. See Get-AzDoBranchPolicy.

.PARAMETER MatchKind
Optional. 'Exact' (default) or 'Prefix'. See BranchName above.

.PARAMETER isEnabled
Whether the policy should be enabled.

.PARAMETER isBlocking
Whether the policy should be blocking.

.PARAMETER PolicySettings
Policy-type-specific settings hashtable.

.EXAMPLE
New-AzDoBranchPolicy -ProjectName 'Fabrikam' -RepositoryName 'FabrikamFiber' -BranchName 'main' -PolicyType 'MinimumReviewerCount' -PolicySettings @{ minimumApproverCount = 2 }

.EXAMPLE
New-AzDoBranchPolicy -ProjectName 'Fabrikam' -RepositoryName 'FabrikamFiber' -BranchName 'release/' -MatchKind 'Prefix' -PolicyType 'MinimumReviewerCount' -PolicySettings @{ minimumApproverCount = 2 }
#>
Function New-AzDoBranchPolicy
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter()][string]$RepositoryName = '',
        [Parameter()][string]$BranchName = '',
        [Parameter(Mandatory = $true)][string]$PolicyType,
        [Parameter()][string]$PolicyIdentifier,
        [Parameter()][ValidateSet('Exact', 'Prefix')][string]$MatchKind = 'Exact',
        [Parameter()][bool]$isEnabled = $true,
        [Parameter()][bool]$isBlocking = $true,
        [Parameter()][HashTable]$PolicySettings,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoBranchPolicy] Creating branch policy '$PolicyType' on '$BranchName'."

    $OrgName    = Get-AzDoOrganizationName
    $project    = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $project)
    {
        Write-Verbose "[New-AzDoBranchPolicy] Project '$ProjectName' not in cache — falling back to live API lookup."
        $project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrgName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($project) { Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects' }
    }

    $repository    = $null
    $hasRepository = -not [string]::IsNullOrWhiteSpace($RepositoryName)

    if ($hasRepository)
    {
        $repoCacheKey = '{0}\{1}' -f $ProjectName, $RepositoryName
        $repository   = Get-CacheItem -Key $repoCacheKey -Type 'LiveRepositories'
        if (-not $repository)
        {
            Write-Verbose "[New-AzDoBranchPolicy] Repository '$RepositoryName' not in cache — falling back to live API lookup."
            $allRepos   = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrgName/$ProjectName/_apis/git/repositories?api-version=7.1-preview.1" -Method Get
            $repository = $allRepos.value | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
            if ($repository) { Add-CacheItem -Key $repoCacheKey -Value $repository -Type 'LiveRepositories' }
        }
    }

    if ((-not $project) -or ($hasRepository -and (-not $repository)))
    {
        Write-Error "[New-AzDoBranchPolicy] Project or Repository not found in cache."
        return
    }

    # Build the scope/settings for the policy. A configuration that already supplied its own
    # 'scope' key (an advanced/manual scope) is respected as-is and nothing here is overridden.
    $settings = if ($PolicySettings) { $PolicySettings } else { @{} }
    if (-not $settings.ContainsKey('scope'))
    {
        $scopeEntry = @{ matchKind = $MatchKind.ToLowerInvariant() }

        if ($repository) { $scopeEntry.repositoryId = $repository.id }

        if (-not [string]::IsNullOrWhiteSpace($BranchName))
        {
            # A literal-prefix strip, not TrimStart('refs/heads/') - TrimStart treats its argument
            # as a set of characters to trim, not a literal prefix, and corrupts a branch name
            # that happens to start with any of those characters.
            $scopeEntry.refName = if ($BranchName -like 'refs/heads/*') { $BranchName } else { 'refs/heads/{0}' -f $BranchName }
        }

        $settings['scope'] = @($scopeEntry)
    }

    # Look up the policy type by name, falling back to a live API call if not cached
    $policyTypeObj = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PolicyType) -Type 'LivePolicyTypes'

    if (-not $policyTypeObj)
    {
        Write-Verbose "[New-AzDoBranchPolicy] PolicyType '$PolicyType' not in cache, querying API."
        $orgUri = 'https://dev.azure.com/{0}/' -f $OrgName
        # Map camelCase/short names to actual Azure DevOps display names returned by the API
        $policyDisplayNameAliases = @{
            'MinimumReviewerCount' = 'Minimum number of reviewers'
            'BuildValidation'      = 'Build'
            'CommentRequirements'  = 'Comment requirements'
            'WorkItemLinking'      = 'Work item linking'
            'MergeStrategy'        = 'Require a merge strategy'
            'StatusCheck'          = 'Status'
        }
        $lookupName = if ($policyDisplayNameAliases.ContainsKey($PolicyType)) { $policyDisplayNameAliases[$PolicyType] } else { $PolicyType }
        $policyTypes = List-DevOpsPolicyTypes -ApiUri $orgUri -ProjectName $ProjectName
        $policyTypeObj = $policyTypes | Where-Object { $_.displayName -eq $lookupName }
        # Also store using both the short name and the actual display name as keys
        if ($policyTypeObj)
        {
            foreach ($pt in $policyTypes)
            {
                Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $pt.displayName) -Value $pt -Type 'LivePolicyTypes' -SuppressWarning
            }
        }
    }

    # Fall back to well-known policy type GUIDs (Azure DevOps built-in types)
    if (-not $policyTypeObj)
    {
        $wellKnownTypeIds = @{
            'MinimumReviewerCount' = 'fa4e907d-c16b-452d-8106-7efa0cb84489'
            'BuildValidation'      = '0609b952-1397-4640-95ec-e00a01b2f659'
            'CommentRequirements'  = 'c6a1889d-b943-4856-b76f-9e46bb6b0df3'
            'WorkItemLinking'      = '40e92b44-2fe1-4dd6-b3d8-74a9c21d0c6e'
        }
        if ($wellKnownTypeIds.ContainsKey($PolicyType))
        {
            $policyTypeObj = [PSCustomObject]@{ id = $wellKnownTypeIds[$PolicyType]; displayName = $PolicyType }
        }
    }

    if (-not $policyTypeObj)
    {
        Write-Error "[New-AzDoBranchPolicy] PolicyType '$PolicyType' not found in cache, API, or well-known types."
        return
    }

    $params = @{
        ApiUri       = 'https://dev.azure.com/{0}/' -f $OrgName
        ProjectName  = $ProjectName
        PolicyTypeId = $policyTypeObj.id
        IsEnabled    = $isEnabled
        IsBlocking   = $isBlocking
        Settings     = $settings
    }

    $value = New-DevOpsBranchPolicy @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoBranchPolicy] New-DevOpsBranchPolicy returned null. Check authentication token and organization settings."
        return
    }

    $cacheKeyParts = @($ProjectName, $RepositoryName, $BranchName, $PolicyType)
    if (-not [string]::IsNullOrWhiteSpace($PolicyIdentifier)) { $cacheKeyParts += $PolicyIdentifier }
    if ($MatchKind -ne 'Exact') { $cacheKeyParts += $MatchKind }
    $cacheKey = $cacheKeyParts -join '\'

    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveBranchPolicies'
    Export-CacheObject -CacheType 'LiveBranchPolicies' -Content $AzDoLiveBranchPolicies
    Refresh-CacheObject -CacheType 'LiveBranchPolicies'
    Write-Verbose "[New-AzDoBranchPolicy] Branch policy created."
}
