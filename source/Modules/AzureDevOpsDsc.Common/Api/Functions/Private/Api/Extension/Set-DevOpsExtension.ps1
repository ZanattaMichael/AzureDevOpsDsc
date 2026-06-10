Function Set-DevOpsExtension
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$PublisherId,
        [Parameter(Mandatory)][string]$ExtensionId,
        [Parameter(Mandatory)][ValidateSet('enabled','disabled','none')][string]$InstallState,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/_apis/extensionmanagement/installedextensionsbyname/{1}/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $PublisherId, $ExtensionId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{
            installState = @{ state = $InstallState }
        } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsExtension] Failed to update extension '$PublisherId.$ExtensionId': $_" }
}
