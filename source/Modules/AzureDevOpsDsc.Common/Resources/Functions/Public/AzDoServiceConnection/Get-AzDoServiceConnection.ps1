Function Get-AzDoServiceConnection
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ConnectionName,
        [Parameter(Mandatory = $true)][string]$ConnectionType,
        [Parameter()][string]$Description,
        [Parameter()][bool]$AllowAllPipelines = $false,
        [Parameter()][HashTable]$Authorization,
        [Parameter()][HashTable]$Data,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoServiceConnection] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $ConnectionName
    $sc = Get-CacheItem -Key $cacheKey -Type 'LiveServiceConnections'

    if (-not $sc)
    {
        Write-Verbose "[Get-AzDoServiceConnection] '$ConnectionName' not in cache — falling back to live API lookup."
        $OrgName = Get-AzDoOrganizationName
        $allSCs  = List-DevOpsServiceConnections -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $sc      = $allSCs | Where-Object { $_.name -eq $ConnectionName } | Select-Object -First 1
        if ($sc) { Add-CacheItem -Key $cacheKey -Value $sc -Type 'LiveServiceConnections' }
    }

    if ($sc)
    {
        Write-Verbose "[Get-AzDoServiceConnection] Service connection '$ConnectionName' found."
        $result.liveCache = $sc
        $result.status    = [DSCGetSummaryState]::Unchanged
    }
    else
    {
        Write-Verbose "[Get-AzDoServiceConnection] Service connection '$ConnectionName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
    }

    return $result
}
