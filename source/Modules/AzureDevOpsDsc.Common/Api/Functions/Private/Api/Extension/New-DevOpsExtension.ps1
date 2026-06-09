Function New-DevOpsExtension
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$PublisherId,
        [Parameter(Mandatory)][string]$ExtensionId,
        [Parameter()][string]$Version,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $uri = '{0}/_apis/extensionmanagement/installedextensionsbyname/{1}/{2}' -f $ApiUri, $PublisherId, $ExtensionId
    if ($Version) { $uri += '/{0}' -f $Version }
    $uri += '?api-version={0}' -f $ApiVersion
    # Uses vssps endpoint — caller should pass vssps URI if needed
    $params = @{
        Uri         = $uri
        Method      = 'POST'
        ContentType = 'application/json'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsExtension] Failed to install extension '$PublisherId.$ExtensionId': $_" }
}
