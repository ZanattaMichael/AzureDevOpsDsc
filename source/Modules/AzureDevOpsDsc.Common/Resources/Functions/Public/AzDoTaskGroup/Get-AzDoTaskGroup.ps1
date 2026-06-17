Function Get-AzDoTaskGroup
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TaskGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$Category,
        [Parameter()][HashTable[]]$Tasks,
        [Parameter()][HashTable[]]$Inputs,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoTaskGroup] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $tg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TaskGroupName) -Type 'LiveTaskGroups'
    if ($tg) { $result.liveCache = $tg; $result.status = [DSCGetSummaryState]::Unchanged }
    else      { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
