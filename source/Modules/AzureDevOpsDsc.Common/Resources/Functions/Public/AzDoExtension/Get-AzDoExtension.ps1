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
    $cacheKey = '{0}\{1}' -f $PublisherId, $ExtensionId
    $ext = Get-CacheItem -Key $cacheKey -Type 'LiveExtensions'
    if (-not $ext)
    {
        Write-Verbose "[Get-AzDoExtension] Extension '$cacheKey' not in cache — falling back to live API lookup."
        $OrgName    = Get-AzDoOrganizationName
        $allExtensions = List-DevOpsExtensions -ApiUri "https://extmgmt.dev.azure.com/$OrgName" -IncludeDisabled $true
        $ext = $allExtensions | Where-Object { $_.publisherId -eq $PublisherId -and $_.extensionId -eq $ExtensionId } | Select-Object -First 1
        if ($ext) { Add-CacheItem -Key $cacheKey -Value $ext -Type 'LiveExtensions' }
    }
    if ($ext) { $result.liveCache = $ext; $result.status = [DSCGetSummaryState]::Unchanged }
    else       { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
