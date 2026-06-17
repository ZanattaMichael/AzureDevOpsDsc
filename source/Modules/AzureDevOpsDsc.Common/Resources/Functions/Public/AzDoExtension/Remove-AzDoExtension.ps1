Function Remove-AzDoExtension
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$PublisherId,
        [Parameter(Mandatory = $true)][string]$ExtensionId,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoExtension] Uninstalling extension '$PublisherId.$ExtensionId'."
    $params = @{
        ApiUri      = 'https://extmgmt.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        PublisherId = $PublisherId
        ExtensionId = $ExtensionId
    }
    Remove-DevOpsExtension @params
    Remove-CacheItem -Key ('{0}\{1}' -f $PublisherId, $ExtensionId) -Type 'LiveExtensions'
    Export-CacheObject -CacheType 'LiveExtensions' -Content $AzDoLiveExtensions
}
