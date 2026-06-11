Function Get-DevOpsRepositorySettings
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$RepositoryId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/git/repositories/{2}/settings?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $RepositoryId, $ApiVersion
        Method = 'GET'
    }
    try
    {
        # The git repository settings endpoint returns the settings object directly,
        # not wrapped in a { value: [...] } envelope.
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch { Throw "[Get-DevOpsRepositorySettings] Failed to get repository settings for '$RepositoryId': $_" }
}
