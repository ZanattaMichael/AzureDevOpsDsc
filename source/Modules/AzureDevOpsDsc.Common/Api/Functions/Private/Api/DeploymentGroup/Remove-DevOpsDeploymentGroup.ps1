Function Remove-DevOpsDeploymentGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$DeploymentGroupId,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/distributedtask/deploymentgroups/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $DeploymentGroupId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsDeploymentGroup] Failed to remove deployment group '$DeploymentGroupId': $_" }
}
