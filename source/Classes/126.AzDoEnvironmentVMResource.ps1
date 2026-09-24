<#
.SYNOPSIS
    DSC resource for managing tags on an Azure DevOps environment virtual machine resource.

.DESCRIPTION
    Manages the tags of a virtual machine resource registered against a pipeline environment
    (`AzDoPipelineEnvironment`). A VM resource can only come into existence by an agent installing
    itself against the environment (`config.cmd`/`config.sh` run on the target machine) - there is
    no REST call that registers one, and this resource deliberately does not add one. DSC owns
    tags and removal of an already-registered resource, never its registration.

.NOTES
    Author: Michael Zanatta

    Registration-limit design, required by the issue this resource implements:
      - `Ensure = 'Present'` with no agent registered under `MachineName`: `Get()` reports
        `status = Error` with `reason = 'AgentNotRegistered'`. Because an `Error` status is still
        routed to `Set()` by the base class (it does not stop the pipeline), `Set()` repeats the
        same check and *throws* - not `Write-Error` - so the failure cannot be silently swallowed
        by the runspace `Invoke-DscResource` runs DSC methods in. The message tells the operator to
        install the agent against this environment first.
      - `Ensure = 'Absent'` with no agent registered under `MachineName`: this already is the
        desired state. `Get()` reports `NotFound`/absent and `Test()` returns `$true` with no
        error - only a *registered* machine that should not be is something `Remove()` acts on.

    Tags are compared case-insensitively as a set, and only when the configuration specifies the
    `Tags` property at all (an unset `Tags` never reads as "must be empty"). Unlike the Kubernetes
    provider, the virtual machines provider does support an in-place tag update (`PATCH
    _apis/distributedtask/environments/{id}/providers/virtualmachines/{resourceId}`), so tag drift
    on an already-registered machine is corrected without recreating the resource or changing its
    id.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as the key
    property for the resource.

.PARAMETER EnvironmentName
    The name of the pipeline environment (`AzDoPipelineEnvironment`) the resource belongs to.

.PARAMETER MachineName
    The name of the machine as registered by the agent. This is how the already-installed VM
    resource is located; it is never used to install or register a new one.

.PARAMETER Tags
    Tags applied to the resource. Compared case-insensitively as a set, and only enforced when
    this property is specified in the configuration.

.EXAMPLE
    AzDoEnvironmentVMResource ProdVM
    {
        ProjectName     = 'Contoso'
        EnvironmentName = 'Production'
        MachineName     = 'prod-vm-01'
        Tags            = @('web', 'prod')
        Ensure          = 'Present'
    }
#>

[DscResource()]
class AzDoEnvironmentVMResource : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$EnvironmentName

    [DscProperty(Mandatory)]
    [System.String]$MachineName

    [DscProperty()]
    [System.String[]]$Tags

    AzDoEnvironmentVMResource()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoEnvironmentVMResource] Get()
    {
        return [AzDoEnvironmentVMResource]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        # Every property is either identity (used to locate the already-registered resource) or
        # Tags (the only thing Set() ever writes), so nothing needs to be stripped from Set()'s
        # parameter set.
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName     = $CurrentResourceObject.ProjectName
        $properties.EnvironmentName = $CurrentResourceObject.EnvironmentName
        $properties.MachineName     = $CurrentResourceObject.MachineName
        $properties.Tags            = $CurrentResourceObject.Tags
        $properties.LookupResult    = $CurrentResourceObject.LookupResult
        $properties.Ensure          = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoEnvironmentVMResource] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
