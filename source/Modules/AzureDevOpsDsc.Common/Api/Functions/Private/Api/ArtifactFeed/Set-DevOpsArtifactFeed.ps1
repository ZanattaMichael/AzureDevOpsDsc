Function Set-DevOpsArtifactFeed
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter()][string]$FeedName,
        [Parameter()][string]$Description,
        [Parameter()][bool]$HideDeletedPackageVersions = $true,
        [Parameter()][bool]$BadgesEnabled = $false,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri }
    $params = @{
        Uri         = '{0}/_apis/packaging/feeds/{1}?api-version={2}' -f $baseUri, $FeedId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{
            name                       = $FeedName
            description                = $Description
            hideDeletedPackageVersions = $HideDeletedPackageVersions
            badgesEnabled              = $BadgesEnabled
        } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsArtifactFeed] Failed to update artifact feed '$FeedId': $_" }
}
