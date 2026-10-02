<#
.SYNOPSIS
Defensive stub - Azure DevOps deployment group targets cannot be created by DSC.

.DESCRIPTION
A deployment group target is registered only by an agent installing itself against the deployment
group (`config.cmd`/`config.sh` run on the target machine). Get-AzDoDeploymentGroupTarget never
returns 'NotFound' for a Present configuration - it returns 'Error' with reason
'AgentNotRegistered', which the base class routes to Set, not New. This function exists only so a
missing-function failure never masks the real error if some other code path ever reaches it; it
throws the same install-the-agent message that Set-AzDoDeploymentGroupTarget throws.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DeploymentGroupName
The name of the deployment group the target belongs to.

.PARAMETER MachineName
The name of the machine as registered by the agent.

.PARAMETER Tags
Tags applied to the target.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoDeploymentGroupTarget -ProjectName 'Contoso' -DeploymentGroupName 'Production' -MachineName 'prod-vm-01'
#>
Function New-AzDoDeploymentGroupTarget
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$DeploymentGroupName,

        [Parameter(Mandatory = $true)]
        [System.String]$MachineName,

        [Parameter()]
        [System.String[]]$Tags,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    throw "[New-AzDoDeploymentGroupTarget] No agent is registered as '$MachineName' in deployment group '$DeploymentGroupName' in project '$ProjectName'. AzDoDeploymentGroupTarget cannot register a deployment group target - install and configure the Azure Pipelines agent against this deployment group first, then re-run this configuration to manage its tags."
}
