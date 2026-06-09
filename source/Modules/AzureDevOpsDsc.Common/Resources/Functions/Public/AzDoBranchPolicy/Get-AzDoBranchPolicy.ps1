Function Get-AzDoBranchPolicy
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoBranchPolicy] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    # Cache key: ProjectName\RepositoryName\BranchName\PolicyType
    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $RepositoryName, $BranchName, $PolicyType
    $policy = Get-CacheItem -Key $cacheKey -Type 'LiveBranchPolicies'

    if ($policy)
    {
        Write-Verbose "[Get-AzDoBranchPolicy] Branch policy found."
        $result.liveCache = $policy

        # Compare key properties
        $changed = @()
        if ($policy.isEnabled  -ne $isEnabled)  { $changed += 'isEnabled' }
        if ($policy.isBlocking -ne $isBlocking) { $changed += 'isBlocking' }

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
