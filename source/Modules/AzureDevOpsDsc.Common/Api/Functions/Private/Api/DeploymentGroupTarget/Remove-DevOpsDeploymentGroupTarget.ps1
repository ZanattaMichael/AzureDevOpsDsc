<#
.SYNOPSIS
Removes a target (machine) from an Azure DevOps deployment group.

.DESCRIPTION
Deletes (de-registers) a deployment group target by id. DSC is allowed to remove a target it did
not register, per the agent-install-only registration design of AzDoDeploymentGroupTarget.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DeploymentGroupId
The id of the deployment group.

.PARAMETER TargetId
The id of the target to delete.

.EXAMPLE
Remove-DevOpsDeploymentGroupTarget -Organization 'myorg' -ProjectName 'MyProject' -DeploymentGroupId 4 -TargetId 7
#>
Function Remove-DevOpsDeploymentGroupTarget
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.Int32]$DeploymentGroupId,

        [Parameter(Mandatory = $true)]
        [System.Int32]$TargetId,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/deploymentgroups/{2}/targets/{3}?api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $DeploymentGroupId, $TargetId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsDeploymentGroupTarget] Failed to delete target '$TargetId' from deployment group '$DeploymentGroupId'. Error: $_"
        return $null
    }
}
