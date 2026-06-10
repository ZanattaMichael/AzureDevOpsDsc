Function Set-DevOpsOrganizationSettings
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][hashtable]$Settings,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/_apis/settings/entries/host?api-version={1}' -f $ApiUri.TrimEnd('/'), $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = $Settings | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsOrganizationSettings] Failed to update organization settings: $_" }
}
