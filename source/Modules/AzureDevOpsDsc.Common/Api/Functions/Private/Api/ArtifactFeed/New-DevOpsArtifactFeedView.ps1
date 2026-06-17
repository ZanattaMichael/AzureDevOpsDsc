Function New-DevOpsArtifactFeedView
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter(Mandatory)][string]$ViewName,
        [Parameter()][string]$ViewType = 'release',
        [Parameter()][string]$ViewVisibility = 'collection',
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri.TrimEnd('/') }
    $params = @{
        Uri         = '{0}/_apis/packaging/feeds/{1}/views?api-version={2}' -f $baseUri, $FeedId, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{ name = $ViewName; type = $ViewType; visibility = $ViewVisibility } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsArtifactFeedView] Failed to create view '$ViewName' on feed '$FeedId': $_" }
}
