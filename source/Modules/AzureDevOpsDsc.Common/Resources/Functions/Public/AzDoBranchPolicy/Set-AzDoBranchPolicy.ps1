Function Set-AzDoBranchPolicy
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

    Write-Verbose "[Set-AzDoBranchPolicy] Updating branch policy '$PolicyType' on '$BranchName'."

    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $RepositoryName, $BranchName, $PolicyType
    $policy = Get-CacheItem -Key $cacheKey -Type 'LiveBranchPolicies'

    if (-not $policy)
    {
        Write-Error "[Set-AzDoBranchPolicy] Branch policy not found in cache."
        return
    }

    $policyTypeObj = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PolicyType) -Type 'LivePolicyTypes'
    $settings = if ($PolicySettings) { $PolicySettings } else { $policy.settings }

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
