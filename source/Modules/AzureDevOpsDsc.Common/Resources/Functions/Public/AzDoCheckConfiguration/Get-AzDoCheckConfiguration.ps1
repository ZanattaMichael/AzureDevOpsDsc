Function Get-AzDoCheckConfiguration
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ResourceName,
        [Parameter(Mandatory = $true)][string]$ResourceType,
        [Parameter(Mandatory = $true)][string]$CheckType,
        [Parameter()][HashTable]$Settings,
        [Parameter()][uint32]$TimeoutInMinutes = 43200,
        [Parameter()][bool]$Enabled = $true,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoCheckConfiguration] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $ResourceType, $ResourceName, $CheckType
    $check = Get-CacheItem -Key $cacheKey -Type 'LiveCheckConfigurations'
    if ($check) { $result.liveCache = $check; $result.status = [DSCGetSummaryState]::Unchanged }
    else         { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
