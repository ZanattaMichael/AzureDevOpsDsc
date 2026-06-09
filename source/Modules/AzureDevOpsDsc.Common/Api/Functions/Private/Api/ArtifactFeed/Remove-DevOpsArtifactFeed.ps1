Function Remove-DevOpsArtifactFeed
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri, $ProjectName } else { $ApiUri }
    $params = @{
        Uri    = '{0}/_apis/packaging/feeds/{1}?api-version={2}' -f $baseUri, $FeedId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsArtifactFeed] Failed to remove artifact feed '$FeedId': $_" }
}
