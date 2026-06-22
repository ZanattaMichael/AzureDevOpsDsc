Function Remove-DevOpsArtifactFeedView
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter(Mandatory)][string]$ViewId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri.TrimEnd('/') }
    $params = @{
        Uri    = '{0}/_apis/packaging/feeds/{1}/views/{2}?api-version={3}' -f $baseUri, $FeedId, $ViewId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsArtifactFeedView] Failed to remove view '$ViewId' from feed '$FeedId': $_" }
}
