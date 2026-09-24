<#
.SYNOPSIS
    DSC resource for managing tags on an Azure DevOps deployment group target.

.DESCRIPTION
    Manages the tags of a target machine registered against a deployment group
    (`AzDoDeploymentGroup`). A target can only come into existence by an agent installing itself
    into the deployment group (`config.cmd`/`config.sh --deploymentgroup` run on the target
    machine) - there is no REST call that registers one, and this resource deliberately does not
    add one. DSC owns tags and removal of an already-registered target, never its registration.

.NOTES
    Author: Michael Zanatta

    Registration-limit design, required by the issue this resource implements:
      - `Ensure = 'Present'` with no agent registered under `MachineName`: `Get()` reports
        `status = Error` with `reason = 'AgentNotRegistered'`. Because an `Error` status is still
        routed to `Set()` by the base class (it does not stop the pipeline), `Set()` repeats the
        same check and *throws* - not `Write-Error` - so the failure cannot be silently swallowed
        by the runspace `Invoke-DscResource` runs DSC methods in. The message tells the operator
        to install the agent against this deployment group first.
      - `Ensure = 'Absent'` with no agent registered under `MachineName`: this already is the
        desired state. `Get()` reports `NotFound`/absent and `Test()` returns `$true` with no
        error - only a *registered* target that should not be is something `Remove()` acts on.

    Tags are compared case-insensitively as a set, and only when the configuration specifies the
    `Tags` property at all (an unset `Tags` never reads as "must be empty"). The deployment group
    targets API supports an in-place tag update (`PATCH
    _apis/distributedtask/deploymentgroups/{id}/targets`), so tag drift on an already-registered
    target is corrected without recreating the target or changing its id.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as the key
    property for the resource.

.PARAMETER DeploymentGroupName
    The name of the deployment group (`AzDoDeploymentGroup`) the target belongs to.

.PARAMETER MachineName
    The name of the machine as registered by the agent. This is how the already-installed target
    is located; it is never used to install or register a new one.

.PARAMETER Tags
    Tags applied to the target. Compared case-insensitively as a set, and only enforced when this
    property is specified in the configuration.

.EXAMPLE
    AzDoDeploymentGroupTarget ProdTarget
    {
        ProjectName         = 'Contoso'
        DeploymentGroupName = 'Production'
        MachineName         = 'prod-vm-01'
        Tags                = @('web', 'prod')
        Ensure              = 'Present'
    }
#>

[DscResource()]
class AzDoDeploymentGroupTarget : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$DeploymentGroupName

    [DscProperty(Mandatory)]
    [System.String]$MachineName

    [DscProperty()]
    [System.String[]]$Tags

    AzDoDeploymentGroupTarget()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoDeploymentGroupTarget] Get()
    {
        return [AzDoDeploymentGroupTarget]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        # Every property is either identity (used to locate the already-registered target) or
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

        $properties.ProjectName         = $CurrentResourceObject.ProjectName
        $properties.DeploymentGroupName = $CurrentResourceObject.DeploymentGroupName
        $properties.MachineName         = $CurrentResourceObject.MachineName
        $properties.Tags                = $CurrentResourceObject.Tags
        $properties.LookupResult        = $CurrentResourceObject.LookupResult
        $properties.Ensure              = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoDeploymentGroupTarget] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
