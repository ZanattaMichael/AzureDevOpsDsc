Function List-DevOpsArtifactFeeds
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri, $ProjectName } else { $ApiUri }
    $params = @{
        Uri    = '{0}/_apis/packaging/feeds?api-version={1}' -f $baseUri, $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsArtifactFeeds] Failed to list artifact feeds: $_" }
}
