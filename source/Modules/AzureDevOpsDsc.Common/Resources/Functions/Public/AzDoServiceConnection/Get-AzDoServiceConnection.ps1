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

    $sc = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Type 'LiveServiceConnections'

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
