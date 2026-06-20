Function Set-DevOpsArtifactFeedView
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter(Mandatory)][string]$ViewId,
        [Parameter()][string]$ViewName,
        [Parameter()][string]$ViewType,
        [Parameter()][string]$ViewVisibility,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri.TrimEnd('/') }

    $body = @{}
    if ($ViewName)       { $body.name       = $ViewName }
    if ($ViewType)       { $body.type       = $ViewType }
    if ($ViewVisibility) { $body.visibility = $ViewVisibility }

    $params = @{
        Uri         = '{0}/_apis/packaging/feeds/{1}/views/{2}?api-version={3}' -f $baseUri, $FeedId, $ViewId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = $body | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsArtifactFeedView] Failed to update view '$ViewId' on feed '$FeedId': $_" }
}
