Function List-DevOpsDeploymentGroups
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/distributedtask/deploymentgroups?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsDeploymentGroups] Failed to list deployment groups for '$ProjectName': $_" }
}
