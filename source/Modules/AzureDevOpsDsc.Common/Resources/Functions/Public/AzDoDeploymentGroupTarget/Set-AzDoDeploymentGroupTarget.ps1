<#
.SYNOPSIS
Updates the tags of an Azure DevOps deployment group target.

.DESCRIPTION
Patches the tags of a target that an agent has already registered. Registration is
agent-install-only by design (see the AzDoDeploymentGroupTarget class notes), so when
Get-AzDoDeploymentGroupTarget reports reason 'AgentNotRegistered' this function throws rather than
writing a non-terminating error - an Error status from Get is still routed here by the base class
rather than stopping the pipeline, so a Write-Error here would otherwise be silently swallowed and
the missing registration would go unnoticed.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DeploymentGroupName
The name of the deployment group the target belongs to.

.PARAMETER MachineName
The name of the machine as registered by the agent.

.PARAMETER Tags
Tags applied to the target. Compared case-insensitively as a set, only when specified.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoDeploymentGroupTarget -ProjectName 'Contoso' -DeploymentGroupName 'Production' -MachineName 'prod-vm-01' -Tags @('web')
#>
Function Set-AzDoDeploymentGroupTarget
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

    Write-Verbose "[Set-AzDoDeploymentGroupTarget] Started."

    if ($LookupResult.reason -eq 'AgentNotRegistered')
    {
        throw "[Set-AzDoDeploymentGroupTarget] No agent is registered as '$MachineName' in deployment group '$DeploymentGroupName' in project '$ProjectName'. AzDoDeploymentGroupTarget cannot register a deployment group target - install and configure the Azure Pipelines agent against this deployment group first, then re-run this configuration to manage its tags."
    }

    if ($LookupResult.reason -eq 'DeploymentGroupNotFound')
    {
        Write-Error "[Set-AzDoDeploymentGroupTarget] Deployment group '$DeploymentGroupName' was not found in project '$ProjectName'."
        return
    }

    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        throw "[Set-AzDoDeploymentGroupTarget] No agent is registered as '$MachineName' in deployment group '$DeploymentGroupName' in project '$ProjectName'. AzDoDeploymentGroupTarget cannot register a deployment group target - install and configure the Azure Pipelines agent against this deployment group first, then re-run this configuration to manage its tags."
    }

    $organization = Get-AzDoOrganizationName

    $updated = Set-DevOpsDeploymentGroupTarget -Organization $organization -ProjectName $ProjectName -DeploymentGroupId $LookupResult.deploymentGroupId -TargetId $existing.id -Tags $Tags

    if ($null -eq $updated)
    {
        Write-Error "[Set-AzDoDeploymentGroupTarget] Failed to update tags on deployment group target '$MachineName' in deployment group '$DeploymentGroupName'."
        return
    }

    Add-CacheItem -Key ('{0}\{1}\{2}' -f $ProjectName, $DeploymentGroupName, $MachineName) -Value $updated -Type 'LiveDeploymentGroupTargets'
    Refresh-CacheObject -CacheType 'LiveDeploymentGroupTargets'

    return $updated
}
