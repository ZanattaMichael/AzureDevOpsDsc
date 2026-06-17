Function Set-DevOpsArtifactFeedPermission
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter(Mandatory)][AllowEmptyCollection()][Object[]]$Permissions,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri.TrimEnd('/') }
    $params = @{
        Uri         = '{0}/_apis/packaging/feeds/{1}/permissions?api-version={2}' -f $baseUri, $FeedId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = (ConvertTo-Json -InputObject @($Permissions) -Depth 5)
    }
    Invoke-AzDevOpsApiRestMethod @params
}
