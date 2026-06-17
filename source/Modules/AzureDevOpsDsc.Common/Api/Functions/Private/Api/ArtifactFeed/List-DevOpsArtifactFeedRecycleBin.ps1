Function List-DevOpsArtifactFeedRecycleBin
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OrganizationName,
        [Parameter()][string]$ProjectName,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $baseUri = if ($ProjectName) {
        'https://feeds.dev.azure.com/{0}/{1}' -f $OrganizationName, $ProjectName
    } else {
        'https://feeds.dev.azure.com/{0}' -f $OrganizationName
    }
    $params = @{
        Uri    = '{0}/_apis/packaging/feedrecyclebin?api-version={1}' -f $baseUri, $ApiVersion
        Method = 'GET'
    }
    try
    {
        $result = Invoke-AzDevOpsApiRestMethod @params
        return $result.value
    }
    catch { Write-Warning "[List-DevOpsArtifactFeedRecycleBin] Failed to list recycle bin: $_"; return @() }
}
