Function Get-AzDoExtension
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$PublisherId,
        [Parameter(Mandatory = $true)][string]$ExtensionId,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force,
        # NotConfigurable DSC properties passed by the base class - accepted but not used
        [Parameter()][string]$Version,
        [Parameter()][string]$DisplayName
    )
    Write-Verbose "[Get-AzDoExtension] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $ext = Get-CacheItem -Key ('{0}\{1}' -f $PublisherId, $ExtensionId) -Type 'LiveExtensions'
    if ($ext) { $result.liveCache = $ext; $result.status = [DSCGetSummaryState]::Unchanged }
    else       { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
