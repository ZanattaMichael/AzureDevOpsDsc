Function List-DevOpsExtensions
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][bool]$IncludeDisabled = $false,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $uri = '{0}/_apis/extensionmanagement/installedextensions?api-version={1}' -f $ApiUri.TrimEnd('/'), $ApiVersion
    if ($IncludeDisabled) { $uri += '&includeDisabledExtensions=true' }
    $params = @{
        Uri    = $uri
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsExtensions] Failed to list installed extensions: $_" }
}
