<#
.SYNOPSIS
Lists the targets (machines) registered against an Azure DevOps deployment group.

.DESCRIPTION
A deployment group target only comes to exist once an agent has installed itself into the
deployment group - there is no Create call here, and none is added: registration is
agent-install-only by design.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DeploymentGroupId
The id of the deployment group.

.EXAMPLE
List-DevOpsDeploymentGroupTargets -Organization 'myorg' -ProjectName 'MyProject' -DeploymentGroupId 4
#>
Function List-DevOpsDeploymentGroupTargets
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.Int32]$DeploymentGroupId,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/deploymentgroups/{2}/targets?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $DeploymentGroupId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsDeploymentGroupTargets] Failed to list targets for deployment group '$DeploymentGroupId'. Error: $_"
        return $null
    }
}
