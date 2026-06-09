Function Remove-DevOpsExtension
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$PublisherId,
        [Parameter(Mandatory)][string]$ExtensionId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/_apis/extensionmanagement/installedextensionsbyname/{1}/{2}?api-version={3}' -f $ApiUri, $PublisherId, $ExtensionId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsExtension] Failed to uninstall extension '$PublisherId.$ExtensionId': $_" }
}
