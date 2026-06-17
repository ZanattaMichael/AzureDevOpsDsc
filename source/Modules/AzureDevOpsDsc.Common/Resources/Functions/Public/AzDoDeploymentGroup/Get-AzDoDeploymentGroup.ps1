Function Get-AzDoDeploymentGroup
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$DeploymentGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string[]]$Tags,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoDeploymentGroup] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $dg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $DeploymentGroupName) -Type 'LiveDeploymentGroups'
    if ($dg) { $result.liveCache = $dg; $result.status = [DSCGetSummaryState]::Unchanged }
    else      { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
