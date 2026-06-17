function List-DevOpsArtifactFeedRecycleBin
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$OrganizationName,
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
        Headers = @{ Authorization = "Bearer $($Global:DSCAZDO_AuthenticationToken.token)" }
    }
    try
    {
        $response = Invoke-RestMethod @params -ErrorAction Stop
        return $response.value
    }
    catch
    {
        Write-Verbose "[List-DevOpsArtifactFeedRecycleBin] Could not list recycle bin: $_"
        return @()
    }
}
