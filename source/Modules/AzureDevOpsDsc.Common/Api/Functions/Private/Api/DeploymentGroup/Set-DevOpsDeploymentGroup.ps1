Function Set-DevOpsDeploymentGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$DeploymentGroupId,
        [Parameter(Mandatory)][string]$DeploymentGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/deploymentgroups/{2}?api-version={3}' -f $ApiUri, $ProjectName, $DeploymentGroupId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{
            name        = $DeploymentGroupName
            description = $Description
        } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsDeploymentGroup] Failed to update deployment group '$DeploymentGroupId': $_" }
}
