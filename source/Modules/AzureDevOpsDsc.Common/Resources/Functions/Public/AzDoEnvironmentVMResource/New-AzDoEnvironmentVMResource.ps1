<#
.SYNOPSIS
Defensive stub - Azure DevOps environment virtual machine resources cannot be created by DSC.

.DESCRIPTION
A VM resource is registered only by an agent installing itself against the environment
(`config.cmd`/`config.sh` run on the target machine). Get-AzDoEnvironmentVMResource never returns
'NotFound' for a Present configuration - it returns 'Error' with reason 'AgentNotRegistered',
which the base class routes to Set, not New. This function exists only so a missing-function
failure never masks the real error if some other code path ever reaches it; it throws the same
install-the-agent message that Set-AzDoEnvironmentVMResource throws.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentName
The name of the pipeline environment the resource belongs to.

.PARAMETER MachineName
The name of the machine as registered by the agent.

.PARAMETER Tags
Tags applied to the resource.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoEnvironmentVMResource -ProjectName 'Contoso' -EnvironmentName 'Production' -MachineName 'prod-vm-01'
#>
Function New-AzDoEnvironmentVMResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$EnvironmentName,

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

    throw "[New-AzDoEnvironmentVMResource] No agent is registered as '$MachineName' on environment '$EnvironmentName' in project '$ProjectName'. AzDoEnvironmentVMResource cannot register a virtual machine resource - install and configure the Azure Pipelines agent against this environment first, then re-run this configuration to manage its tags."
}
