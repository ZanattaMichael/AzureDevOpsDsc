<#
.SYNOPSIS
Updates an existing Azure DevOps branch policy.

.DESCRIPTION
Looks the policy up in the cache (by the same key Get-AzDoBranchPolicy computes for this
resource instance) and PUTs the desired isEnabled/isBlocking/PolicySettings over it.

If PolicySettings is supplied but does not itself contain a 'scope' key, the cached policy's
existing scope is carried over rather than dropped - the API's settings PUT replaces the whole
settings object, and scope lives inside it, so omitting it here would silently reset a prefix,
repository-wide or cross-repository scope back to nothing on the very next settings change.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER RepositoryName
The Git repository name used to resolve this resource instance's cache key. See the class help.

.PARAMETER BranchName
The branch ref name (or prefix) used to resolve this resource instance's cache key.

.PARAMETER PolicyType
The policy type display name or short alias.

.PARAMETER PolicyIdentifier
Optional. Used to resolve this resource instance's cache key when several policies of the same
PolicyType exist in the same scope. See Get-AzDoBranchPolicy.

.PARAMETER MatchKind
Optional. 'Exact' (default) or 'Prefix'. Used to resolve this resource instance's cache key.

.PARAMETER isEnabled
Whether the policy should be enabled.

.PARAMETER isBlocking
Whether the policy should be blocking.

.PARAMETER PolicySettings
Policy-type-specific settings hashtable to write. Falls back to the cached policy's current
settings when not supplied.

.EXAMPLE
Set-AzDoBranchPolicy -ProjectName 'Fabrikam' -RepositoryName 'FabrikamFiber' -BranchName 'main' -PolicyType 'MinimumReviewerCount' -PolicySettings @{ minimumApproverCount = 2 }
#>
Function Set-AzDoBranchPolicy
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

    Write-Verbose "[Set-AzDoBranchPolicy] Updating branch policy '$PolicyType' on '$BranchName'."

    $cacheKeyParts = @($ProjectName, $RepositoryName, $BranchName, $PolicyType)
    if (-not [string]::IsNullOrWhiteSpace($PolicyIdentifier)) { $cacheKeyParts += $PolicyIdentifier }
    if ($MatchKind -ne 'Exact') { $cacheKeyParts += $MatchKind }
    $cacheKey = $cacheKeyParts -join '\'

    $policy = Get-CacheItem -Key $cacheKey -Type 'LiveBranchPolicies'

    if (-not $policy)
    {
        Write-Error "[Set-AzDoBranchPolicy] Branch policy not found in cache."
        return
    }

    $policyTypeObj = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PolicyType) -Type 'LivePolicyTypes'
    $settings = if ($PolicySettings) { $PolicySettings } else { $policy.settings }

    # The API replaces the whole settings object on PUT, and scope lives inside it - carry the
    # cached policy's existing scope over unless the configuration supplied its own.
    if ($PolicySettings -and (-not $PolicySettings.ContainsKey('scope')))
    {
        $settings['scope'] = $policy.settings.scope
    }

    $params = @{
        ApiUri       = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName  = $ProjectName
        PolicyId     = $policy.id
        PolicyTypeId = if ($policyTypeObj) { $policyTypeObj.id } else { $policy.type.id }
        IsEnabled    = $isEnabled
        IsBlocking   = $isBlocking
        Settings     = $settings
    }

    $value = Set-DevOpsBranchPolicy @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoBranchPolicy] Set-DevOpsBranchPolicy returned null. Check authentication token and organization settings."
        return
    }

    Add-CacheItem -Key $cacheKey -Value $value -Type 'LiveBranchPolicies'
    Export-CacheObject -CacheType 'LiveBranchPolicies' -Content $AzDoLiveBranchPolicies
    Refresh-CacheObject -CacheType 'LiveBranchPolicies'
    Write-Verbose "[Set-AzDoBranchPolicy] Branch policy updated."
}
