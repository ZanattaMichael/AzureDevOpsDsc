Function List-DevOpsWikis
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $uri = '{0}/_apis/wiki/wikis?api-version={1}' -f $ApiUri, $ApiVersion
    if ($ProjectName) { $uri += '&project={0}' -f $ProjectName }
    $params = @{
        Uri    = $uri
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsWikis] Failed to list wikis: $_" }
}
