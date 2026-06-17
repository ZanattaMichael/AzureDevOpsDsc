Function List-DevOpsVariableGroups
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter()][string]$ApiVersion = '7.1-preview.2'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/distributedtask/variablegroups?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsVariableGroups] Failed to list variable groups for '$ProjectName': $_" }
}
