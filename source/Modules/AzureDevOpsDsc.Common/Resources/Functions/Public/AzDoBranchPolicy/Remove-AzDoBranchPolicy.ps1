Function Remove-AzDoBranchPolicy
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$BranchName,
        [Parameter(Mandatory = $true)][string]$PolicyType,
        [Parameter()][bool]$isEnabled = $true,
        [Parameter()][bool]$isBlocking = $true,
        [Parameter()][HashTable]$PolicySettings,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoBranchPolicy] Removing branch policy '$PolicyType' on '$BranchName'."

    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $RepositoryName, $BranchName, $PolicyType
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
