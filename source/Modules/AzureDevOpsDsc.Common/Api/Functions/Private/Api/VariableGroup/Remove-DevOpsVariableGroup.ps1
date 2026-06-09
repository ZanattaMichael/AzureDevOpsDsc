Function Remove-DevOpsVariableGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$VariableGroupId,
        [Parameter()][string]$ApiVersion = '7.1-preview.2'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/distributedtask/variablegroups/{2}?api-version={3}' -f $ApiUri, $ProjectName, $VariableGroupId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsVariableGroup] Failed to remove variable group '$VariableGroupId': $_" }
}
