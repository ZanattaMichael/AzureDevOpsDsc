Function Get-AzDoPipelineEnvironment
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$EnvironmentName,
        [Parameter()][string]$Description,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoPipelineEnvironment] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $env = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'
    if ($env) { $result.liveCache = $env; $result.status = [DSCGetSummaryState]::Unchanged }
    else       { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
