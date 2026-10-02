# DSC AzDoDeploymentGroupTarget Resource

## Syntax

```PowerShell
AzDoDeploymentGroupTarget [string] #ResourceName
{
    ProjectName         = [String]$ProjectName
    DeploymentGroupName = [String]$DeploymentGroupName
    MachineName         = [String]$MachineName
    [ Tags              = [String[]]$Tags ]
    [ Ensure            = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **DeploymentGroupName**: The name of the deployment group (`AzDoDeploymentGroup`) the target belongs to.
- **MachineName**: The name of the machine as registered by the agent. This is how the already-installed target is located; it is never used to install or register a new one.
- **Tags**: An array of tag strings, compared case-insensitively as a set, and only enforced when this property is specified.
- **Ensure**: Specifies whether the target should exist. Valid values are `Present` and `Absent`.

## Additional Information

A deployment group target can only come into existence by an agent installing itself into the deployment group (`config.cmd`/`config.sh --deploymentgroup` run on the target machine) — there is no REST call that registers one, and this resource deliberately does not add one. DSC owns tags and removal of an already-registered target, never its registration.

Registration-limit design:

- `Ensure = 'Present'` with no agent registered under `MachineName`: `Get()` reports `status = Error` with `reason = 'AgentNotRegistered'`. Because an `Error` status is still routed to `Set()` by the base class, `Set()` repeats the same check and **throws** — not `Write-Error` — so the failure cannot be silently swallowed. The message tells the operator to install the agent against this deployment group first.
- `Ensure = 'Absent'` with no agent registered under `MachineName`: this already is the desired state. `Get()` reports `Unchanged`/absent and `Test()` returns `$true` with no error — only a *registered* target that should not be is something `Remove()` acts on.

The deployment group targets API supports an in-place tag update (`PATCH _apis/distributedtask/deploymentgroups/{id}/targets`), so tag drift on an already-registered target is corrected without recreating the target or changing its id.

## Examples

## Example 1: Sample Configuration using AzDoDeploymentGroupTarget Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoDeploymentGroupTarget ProdTarget {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
            MachineName         = 'prod-vm-01'
            Tags                = @('web', 'prod')
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoDeploymentGroupTarget
$properties = @{
    ProjectName         = 'MyProject'
    DeploymentGroupName = 'ProductionServers'
    MachineName         = 'prod-vm-01'
}

Invoke-DscResource -Name 'AzDoDeploymentGroupTarget' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  DeploymentGroupName: ProductionServers
}

resources:
- name: Production Target Tags
  type: AzureDevOpsDscNative/AzDoDeploymentGroupTarget
  dependsOn:
    - AzureDevOpsDscNative/AzDoDeploymentGroup/ProductionServers
  properties:
    ProjectName: $ProjectName
    DeploymentGroupName: $DeploymentGroupName
    MachineName: prod-vm-01
    Tags:
      - web
      - prod
    Ensure: Present
```

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
