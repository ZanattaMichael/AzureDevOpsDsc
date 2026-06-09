Function Get-DevOpsOrganizationSettings
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/_apis/settings/entries/host?api-version={1}' -f $ApiUri, $ApiVersion
        Method = 'GET'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Get-DevOpsOrganizationSettings] Failed to retrieve organization settings: $_" }
}
