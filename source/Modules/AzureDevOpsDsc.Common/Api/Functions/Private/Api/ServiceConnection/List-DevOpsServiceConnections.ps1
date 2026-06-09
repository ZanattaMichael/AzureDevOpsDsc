Function List-DevOpsServiceConnections
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter()][string]$Type,
        [Parameter()][string]$ApiVersion = '7.1-preview.4'
    )
    $uri = '{0}/{1}/_apis/serviceendpoint/endpoints?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
    if ($Type) { $uri += '&type={0}' -f $Type }
    $params = @{
        Uri    = $uri
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsServiceConnections] Failed to list service connections for '$ProjectName': $_" }
}
