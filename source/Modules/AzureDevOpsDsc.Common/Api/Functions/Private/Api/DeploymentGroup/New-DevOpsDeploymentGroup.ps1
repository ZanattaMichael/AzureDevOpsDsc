Function New-DevOpsDeploymentGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$DeploymentGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/deploymentgroups?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name        = $DeploymentGroupName
            description = $Description
        } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsDeploymentGroup] Failed to create deployment group '$DeploymentGroupName': $_" }
}
