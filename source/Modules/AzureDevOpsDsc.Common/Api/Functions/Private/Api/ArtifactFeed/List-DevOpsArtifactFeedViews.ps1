Function List-DevOpsArtifactFeedViews
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri.TrimEnd('/') }
    $params = @{
        Uri    = '{0}/_apis/packaging/feeds/{1}/views?api-version={2}' -f $baseUri, $FeedId, $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsArtifactFeedViews] Failed to list views for feed '$FeedId': $_" }
}
