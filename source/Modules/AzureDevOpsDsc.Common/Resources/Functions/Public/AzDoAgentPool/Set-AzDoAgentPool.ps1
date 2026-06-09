Function Set-AzDoAgentPool
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
    Write-Verbose "[Set-AzDoAgentPool] Updating agent pool '$PoolName'."
    $pool = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    if (-not $pool) { Write-Error "[Set-AzDoAgentPool] Pool not found."; return }
    $params = @{
        ApiUri       = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        PoolId       = $pool.id
        PoolName     = $PoolName
        AutoProvision = $AutoProvision
        AutoUpdate   = $AutoUpdate
    }
    $value = Set-DevOpsAgentPool @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoAgentPool] Set-DevOpsAgentPool returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key $PoolName -Value $value -Type 'LiveAgentPools'
    Export-CacheObject -CacheType 'LiveAgentPools' -Content $AzDoLiveAgentPools
    Refresh-CacheObject -CacheType 'LiveAgentPools'
}
