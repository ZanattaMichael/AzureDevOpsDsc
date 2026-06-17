Function Remove-AzDoAgentPool
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$PoolName,
        [Parameter()][string]$PoolType = 'automation',
        [Parameter()][bool]$AutoProvision = $false,
        [Parameter()][bool]$AutoUpdate = $true,
        [Parameter()][bool]$IsHosted = $false,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoAgentPool] Removing agent pool '$PoolName'."
    $pool = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    if (-not $pool) { Write-Error "[Remove-AzDoAgentPool] Pool not found."; return }
    $params = @{
        ApiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        PoolId = $pool.id
    }
    Remove-DevOpsAgentPool @params
    Remove-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    Export-CacheObject -CacheType 'LiveAgentPools' -Content $AzDoLiveAgentPools
}
