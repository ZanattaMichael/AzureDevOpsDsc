<#
.SYNOPSIS
Removes an Azure DevOps branch policy.

.DESCRIPTION
Looks the policy up in the cache (by the same key Get-AzDoBranchPolicy computes for this
resource instance) and deletes it.

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
Not used by removal; accepted so the resource's full property set can be passed uniformly.

.PARAMETER isBlocking
Not used by removal; accepted so the resource's full property set can be passed uniformly.

.PARAMETER PolicySettings
Not used by removal; accepted so the resource's full property set can be passed uniformly.

.EXAMPLE
Remove-AzDoBranchPolicy -ProjectName 'Fabrikam' -RepositoryName 'FabrikamFiber' -BranchName 'main' -PolicyType 'MinimumReviewerCount'
#>
Function Remove-AzDoBranchPolicy
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

    Write-Verbose "[Remove-AzDoBranchPolicy] Removing branch policy '$PolicyType' on '$BranchName'."

    $cacheKeyParts = @($ProjectName, $RepositoryName, $BranchName, $PolicyType)
    if (-not [string]::IsNullOrWhiteSpace($PolicyIdentifier)) { $cacheKeyParts += $PolicyIdentifier }
    if ($MatchKind -ne 'Exact') { $cacheKeyParts += $MatchKind }
    $cacheKey = $cacheKeyParts -join '\'

    $policy = Get-CacheItem -Key $cacheKey -Type 'LiveBranchPolicies'

    if (-not $policy)
    {
        Write-Error "[Remove-AzDoBranchPolicy] Branch policy not found in cache."
        return
    }

    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName = $ProjectName
        PolicyId    = $policy.id
    }

    Remove-DevOpsBranchPolicy @params

    Remove-CacheItem -Key $cacheKey -Type 'LiveBranchPolicies'
    Export-CacheObject -CacheType 'LiveBranchPolicies' -Content $AzDoLiveBranchPolicies
    Write-Verbose "[Remove-AzDoBranchPolicy] Branch policy removed."
}
