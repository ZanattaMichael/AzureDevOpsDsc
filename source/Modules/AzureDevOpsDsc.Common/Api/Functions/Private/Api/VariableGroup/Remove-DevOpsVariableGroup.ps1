Function Remove-DevOpsVariableGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        # Project GUID(s) the variable group should be removed from. Deletion is an
        # organization-level operation that takes the projects via a 'projectIds' query
        # parameter; the project-scoped URL returns 405 (Method Not Allowed) for DELETE.
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][Object]$VariableGroupId,
        [Parameter()][string]$ApiVersion = '7.1-preview.2'
    )
    $params = @{
        Uri    = '{0}/_apis/distributedtask/variablegroups/{1}?projectIds={2}&api-version={3}' -f $ApiUri.TrimEnd('/'), $VariableGroupId, $ProjectId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsVariableGroup] Failed to remove variable group '$VariableGroupId': $_" }
}
