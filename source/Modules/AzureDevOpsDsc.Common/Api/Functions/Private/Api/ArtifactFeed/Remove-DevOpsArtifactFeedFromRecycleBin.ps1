Function Remove-DevOpsArtifactFeedFromRecycleBin
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OrganizationName,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) {
        'https://feeds.dev.azure.com/{0}/{1}' -f $OrganizationName, $ProjectName
    } else {
        'https://feeds.dev.azure.com/{0}' -f $OrganizationName
    }
    $params = @{
        Uri    = '{0}/_apis/packaging/feedrecyclebin/{1}?api-version={2}' -f $baseUri, $FeedId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Write-Warning "[Remove-DevOpsArtifactFeedFromRecycleBin] Failed to purge feed '$FeedId': $_" }
}
