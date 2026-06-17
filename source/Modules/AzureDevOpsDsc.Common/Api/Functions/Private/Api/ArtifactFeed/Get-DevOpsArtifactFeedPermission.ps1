Function Get-DevOpsArtifactFeedPermission
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
        Uri    = '{0}/_apis/packaging/feeds/{1}/permissions?api-version={2}' -f $baseUri, $FeedId, $ApiVersion
        Method = 'GET'
    }
    $result = Invoke-AzDevOpsApiRestMethod @params
    if ($null -eq $result -or $null -eq $result.value) { return @() }
    return $result.value
}
