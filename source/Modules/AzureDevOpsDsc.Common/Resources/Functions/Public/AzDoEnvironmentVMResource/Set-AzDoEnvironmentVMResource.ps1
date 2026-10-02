<#
.SYNOPSIS
Updates the tags of an Azure DevOps environment virtual machine resource.

.DESCRIPTION
Patches the tags of a VM resource that an agent has already registered. Registration is
agent-install-only by design (see the AzDoEnvironmentVMResource class notes), so when
Get-AzDoEnvironmentVMResource reports reason 'AgentNotRegistered' this function throws rather
than writing a non-terminating error - an Error status from Get is still routed here by the base
class rather than stopping the pipeline, so a Write-Error here would otherwise be silently
swallowed and the missing registration would go unnoticed.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentName
The name of the pipeline environment the resource belongs to.

.PARAMETER MachineName
The name of the machine as registered by the agent.

.PARAMETER Tags
Tags applied to the resource. Compared case-insensitively as a set, only when specified.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoEnvironmentVMResource -ProjectName 'Contoso' -EnvironmentName 'Production' -MachineName 'prod-vm-01' -Tags @('web')
#>
Function Set-AzDoEnvironmentVMResource
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

    Write-Verbose "[Set-AzDoEnvironmentVMResource] Started."

    if ($LookupResult.reason -eq 'AgentNotRegistered')
    {
        throw "[Set-AzDoEnvironmentVMResource] No agent is registered as '$MachineName' on environment '$EnvironmentName' in project '$ProjectName'. AzDoEnvironmentVMResource cannot register a virtual machine resource - install and configure the Azure Pipelines agent against this environment first, then re-run this configuration to manage its tags."
    }

    if ($LookupResult.reason -eq 'EnvironmentNotFound')
    {
        Write-Error "[Set-AzDoEnvironmentVMResource] Environment '$EnvironmentName' was not found in project '$ProjectName'."
        return
    }

    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        throw "[Set-AzDoEnvironmentVMResource] No agent is registered as '$MachineName' on environment '$EnvironmentName' in project '$ProjectName'. AzDoEnvironmentVMResource cannot register a virtual machine resource - install and configure the Azure Pipelines agent against this environment first, then re-run this configuration to manage its tags."
    }

    $organization = Get-AzDoOrganizationName

    $updated = Set-DevOpsEnvironmentVMResource -Organization $organization -ProjectName $ProjectName -EnvironmentId $LookupResult.environmentId -ResourceId $existing.id -Tags $Tags

    if ($null -eq $updated)
    {
        Write-Error "[Set-AzDoEnvironmentVMResource] Failed to update tags on virtual machine resource '$MachineName' on environment '$EnvironmentName'."
        return
    }

    Add-CacheItem -Key ('{0}\{1}\{2}' -f $ProjectName, $EnvironmentName, $MachineName) -Value $updated -Type 'LiveEnvironmentVMResources'
    Refresh-CacheObject -CacheType 'LiveEnvironmentVMResources'

    return $updated
}
