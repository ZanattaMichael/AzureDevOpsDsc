Function Remove-DevOpsWiki
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$WikiId,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/_apis/wiki/wikis/{1}?api-version={2}' -f $ApiUri, $WikiId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsWiki] Failed to remove wiki '$WikiId': $_" }
}
