Function New-AzDoExtension
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$PublisherId,
        [Parameter(Mandatory = $true)][string]$ExtensionId,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[New-AzDoExtension] Installing extension '$PublisherId.$ExtensionId'."
    $params = @{
        ApiUri      = 'https://extmgmt.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        PublisherId = $PublisherId
        ExtensionId = $ExtensionId
    }
    $value = New-DevOpsExtension @params
    Add-CacheItem -Key ('{0}\{1}' -f $PublisherId, $ExtensionId) -Value $value -Type 'LiveExtensions'
    Export-CacheObject -CacheType 'LiveExtensions' -Content $AzDoLiveExtensions
    Refresh-CacheObject -CacheType 'LiveExtensions'
}
