Function New-AzDoAgentQueue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$QueueName,
        [Parameter(Mandatory = $true)][string]$PoolName,
        [Parameter()][bool]$AuthorizeAllPipelines = $false,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[New-AzDoAgentQueue] Creating agent queue '$QueueName'."
    $OrganizationName = Get-AzDoOrganizationName
    $pool = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'

    if (-not $pool)
    {
        Write-Verbose "[New-AzDoAgentQueue] Pool '$PoolName' not in cache — falling back to live API lookup."
        $allPools = List-DevOpsAgentPools -ApiUri "https://dev.azure.com/$OrganizationName"
        $pool = $allPools | Where-Object { $_.name -eq $PoolName } | Select-Object -First 1
        if ($pool) { Add-CacheItem -Key $PoolName -Value $pool -Type 'LiveAgentPools' }
    }

    if (-not $pool) { Write-Error "[New-AzDoAgentQueue] Pool '$PoolName' not found."; return }
    $params = @{
        ApiUri               = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName          = $ProjectName
        QueueName            = $QueueName
        PoolId               = $pool.id
        AuthorizeAllPipelines = $AuthorizeAllPipelines
    }
    $value = New-DevOpsAgentQueue @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoAgentQueue] New-DevOpsAgentQueue returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $QueueName) -Value $value -Type 'LiveAgentQueues'
    Export-CacheObject -CacheType 'LiveAgentQueues' -Content $AzDoLiveAgentQueues
    Refresh-CacheObject -CacheType 'LiveAgentQueues'
}
