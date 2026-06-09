Function New-AzDoAgentPool
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
    Write-Verbose "[New-AzDoAgentPool] Creating agent pool '$PoolName'."
    $params = @{
        ApiUri       = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        PoolName     = $PoolName
        PoolType     = $PoolType
        AutoProvision = $AutoProvision
        AutoUpdate   = $AutoUpdate
        IsHosted     = $IsHosted
    }
    $value = New-DevOpsAgentPool @params
    Add-CacheItem -Key $PoolName -Value $value -Type 'LiveAgentPools'
    Export-CacheObject -CacheType 'LiveAgentPools' -Content $AzDoLiveAgentPools
    Refresh-CacheObject -CacheType 'LiveAgentPools'
}
