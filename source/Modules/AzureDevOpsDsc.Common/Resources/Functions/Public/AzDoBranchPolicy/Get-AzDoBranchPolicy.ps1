<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps branch policy.

.DESCRIPTION
Looks the policy up live and compares it against the desired state.

The lookup has to reason about the policy's whole scope, not just a repository and a branch: an
empty RepositoryName means the policy applies to every repository in the project (cross-repo), an
empty BranchName means it applies to the whole repository rather than one branch (a repository
settings policy such as file size or path length restriction), and MatchKind chooses whether
BranchName names one branch exactly or a prefix shared by several ('release/' for every
'release/*' branch). The API's per-ref lookup endpoint cannot express any of the last three, so
every policy of the matching type is fetched and matched against the desired scope client-side -
see Test-AzDoBranchPolicyScopeMatch.

Several policies of the same PolicyType can exist in the same scope (two build validation
policies pointing at different pipelines, several status checks). PolicyIdentifier resolves which
one this resource instance is - see Test-AzDoBranchPolicyIdentifierMatch and the PolicyIdentifier
parameter below. Leaving it unset preserves the original behaviour of matching the first policy of
that type found in the scope.

Only the PolicySettings keys the configuration states are compared against the API's
policy.settings, through ConvertTo-NormalizedPolicySettingValue - a key the configuration did not
state is not read as "must be empty", and a value that round-trips through the API as a different
.NET type (or a differently-cased/ordered object) is not read as drift.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER RepositoryName
The Git repository name. Leave empty for a cross-repository policy scope (applies to every
repository in the project).

.PARAMETER BranchName
The branch ref name (with or without the 'refs/heads/' prefix), or a branch-name prefix when
MatchKind is 'Prefix'. Leave empty for a repository-wide policy scope (no branch restriction) -
only meaningful for policy types that do not require a ref, such as the repository settings
policies.

.PARAMETER PolicyType
The policy type display name or short alias (e.g. 'MinimumReviewerCount').

.PARAMETER PolicyIdentifier
Optional. A value expected to appear among this policy's settings (a buildDefinitionId, a status
check name, a required reviewer's display name, ...), used to tell apart several policies of the
same PolicyType in the same scope. Unset behaves exactly as before this parameter existed: the
first policy of that type found in the scope is used.

.PARAMETER MatchKind
Optional. 'Exact' (default) matches BranchName as one branch; 'Prefix' matches every branch whose
ref name starts with BranchName.

.PARAMETER isEnabled
Whether the policy is expected to be enabled.

.PARAMETER isBlocking
Whether the policy is expected to be blocking.

.PARAMETER PolicySettings
Policy-type-specific settings hashtable. Only the keys present here are compared against the
live policy's settings; the 'scope' key, if present, is not compared as a setting (scope is
compared through RepositoryName/BranchName/MatchKind instead).

.EXAMPLE
Get-AzDoBranchPolicy -ProjectName 'Fabrikam' -RepositoryName 'FabrikamFiber' -BranchName 'main' -PolicyType 'MinimumReviewerCount'

.EXAMPLE
Get-AzDoBranchPolicy -ProjectName 'Fabrikam' -RepositoryName 'FabrikamFiber' -BranchName 'release/' -MatchKind 'Prefix' -PolicyType 'MinimumReviewerCount'

.EXAMPLE
Get-AzDoBranchPolicy -ProjectName 'Fabrikam' -BranchName 'main' -PolicyType 'MinimumReviewerCount'
Cross-repository lookup (no RepositoryName): matches a policy scoped to every repository.
#>
Function Get-AzDoBranchPolicy
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoBranchPolicy] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    $hasRepository = -not [string]::IsNullOrWhiteSpace($RepositoryName)
    $hasBranch     = -not [string]::IsNullOrWhiteSpace($BranchName)

    # Cache key: ProjectName\RepositoryName\BranchName\PolicyType[\PolicyIdentifier][\MatchKind]
    # The last two segments are only appended when set, so an unset PolicyIdentifier/default
    # MatchKind reproduce the original 4-part key exactly - existing configurations keep hitting
    # the same cache entry they always did.
    $cacheKeyParts = @($ProjectName, $RepositoryName, $BranchName, $PolicyType)
    if (-not [string]::IsNullOrWhiteSpace($PolicyIdentifier)) { $cacheKeyParts += $PolicyIdentifier }
    if ($MatchKind -ne 'Exact') { $cacheKeyParts += $MatchKind }
    $cacheKey = $cacheKeyParts -join '\'

    $policy = Get-CacheItem -Key $cacheKey -Type 'LiveBranchPolicies'

    if (-not $policy)
    {
        Write-Verbose "[Get-AzDoBranchPolicy] Policy not in cache — falling back to live API lookup."
        $OrgName = Get-AzDoOrganizationName

        $repositoryCache = $null

        if ($hasRepository)
        {
            $repoCacheKey    = '{0}\{1}' -f $ProjectName, $RepositoryName
            $repositoryCache = Get-CacheItem -Key $repoCacheKey -Type 'LiveRepositories'
            if (-not $repositoryCache)
            {
                $allRepos        = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrgName/$ProjectName/_apis/git/repositories?api-version=7.1-preview.1" -Method Get
                $repositoryCache = $allRepos.value | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
                if ($repositoryCache) { Add-CacheItem -Key $repoCacheKey -Value $repositoryCache -Type 'LiveRepositories' }
            }
        }

        if ((-not $hasRepository) -or $repositoryCache)
        {
            # Live policies carry Azure DevOps' display name (e.g. 'Comment requirements'), not the
            # short code used in config (e.g. 'CommentRequirements') - translate before matching.
            $policyDisplayNameAliases = @{
                'MinimumReviewerCount' = 'Minimum number of reviewers'
                'BuildValidation'      = 'Build'
                'CommentRequirements'  = 'Comment requirements'
                'WorkItemLinking'      = 'Work item linking'
                'MergeStrategy'        = 'Require a merge strategy'
                'StatusCheck'          = 'Status'
            }
            $lookupDisplayName = if ($policyDisplayNameAliases.ContainsKey($PolicyType)) { $policyDisplayNameAliases[$PolicyType] } else { $PolicyType }

            # A literal-prefix strip, not TrimStart('refs/heads/') - TrimStart treats its argument
            # as a set of characters to trim, not a literal prefix, and corrupts a branch name that
            # happens to start with any of those characters (e.g. 'feature/refs-cleanup').
            $desiredRefName = if ($hasBranch)
            {
                if ($BranchName -like 'refs/heads/*') { $BranchName } else { 'refs/heads/{0}' -f $BranchName }
            }
            else
            {
                $null
            }

            $listParams = @{
                ApiUri      = "https://dev.azure.com/$OrgName"
                ProjectName = $ProjectName
            }
            if ($repositoryCache) { $listParams.RepositoryId = $repositoryCache.id }
            # RefName is intentionally not passed to the API here: a prefix, repository-wide or
            # cross-repository scope cannot be expressed by the API's single refName filter, so
            # every candidate policy is fetched and matched against the full desired scope below.
            $allPolicies = List-DevOpsBranchPolicies @listParams

            $candidates = $allPolicies | Where-Object { $_.type.displayName -eq $lookupDisplayName }

            if (-not [string]::IsNullOrWhiteSpace($PolicyIdentifier))
            {
                $candidates = $candidates | Where-Object { Test-AzDoBranchPolicyIdentifierMatch -Settings $_.settings -PolicyIdentifier $PolicyIdentifier }
            }

            $desiredRepositoryId = if ($repositoryCache) { $repositoryCache.id } else { $null }
            $policy = $candidates | Where-Object {
                Test-AzDoBranchPolicyScopeMatch -PolicyScope $_.scope -RepositoryId $desiredRepositoryId -RefName $desiredRefName -MatchKind $MatchKind
            } | Select-Object -First 1

            if ($policy) { Add-CacheItem -Key $cacheKey -Value $policy -Type 'LiveBranchPolicies' }
        }
    }

    if ($policy)
    {
        Write-Verbose "[Get-AzDoBranchPolicy] Branch policy found."
        $result.liveCache = $policy

        # Compare key properties
        $changed = @()
        if ($policy.isEnabled  -ne $isEnabled)  { $changed += 'isEnabled' }
        if ($policy.isBlocking -ne $isBlocking) { $changed += 'isBlocking' }

        # Only the settings keys the configuration stated are compared - an unspecified key is not
        # read as "must be empty", and both sides are normalized first so a differently-typed or
        # differently-shaped (but equal) value from the API is not read as drift.
        if ($PolicySettings)
        {
            foreach ($settingKey in $PolicySettings.Keys)
            {
                if ($settingKey -eq 'scope') { continue }

                $liveSettings = $policy.settings
                $liveValue    = $null
                if ($liveSettings -is [System.Collections.IDictionary])
                {
                    if ($liveSettings.ContainsKey($settingKey)) { $liveValue = $liveSettings[$settingKey] }
                }
                elseif (($null -ne $liveSettings) -and ($liveSettings.PSObject.Properties.Match($settingKey).Count -gt 0))
                {
                    $liveValue = $liveSettings.$settingKey
                }

                $desiredNormalized = ConvertTo-NormalizedPolicySettingValue -Value $PolicySettings[$settingKey]
                $liveNormalized     = ConvertTo-NormalizedPolicySettingValue -Value $liveValue

                if ($desiredNormalized -ne $liveNormalized)
                {
                    $changed += "PolicySettings.$settingKey"
                }
            }
        }

        $result.propertiesChanged = $changed
        $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }
    }
    else
    {
        Write-Verbose "[Get-AzDoBranchPolicy] Branch policy not found."
        $result.status = [DSCGetSummaryState]::NotFound
    }

    return $result
}
