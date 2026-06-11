function Remove-DevOpsArtifactFeedFromRecycleBin
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$OrganizationName,
        [Parameter(Mandatory = $true)][string]$FeedId,
        [Parameter()][string]$ProjectName,
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
        Headers = @{ Authorization = "Bearer $($Global:DSCAZDO_AuthenticationToken.token)" }
    }
    try
    {
        Invoke-RestMethod @params -ErrorAction Stop | Out-Null
        Write-Verbose "[Remove-DevOpsArtifactFeedFromRecycleBin] Permanently deleted feed '$FeedId' from recycle bin."
    }
    catch
    {
        Write-Verbose "[Remove-DevOpsArtifactFeedFromRecycleBin] Could not purge feed '$FeedId' from recycle bin: $_"
    }
}
