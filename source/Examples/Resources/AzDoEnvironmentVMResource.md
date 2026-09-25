# DSC AzDoEnvironmentVMResource Resource

## Syntax

```PowerShell
AzDoEnvironmentVMResource [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    EnvironmentName = [String]$EnvironmentName
    MachineName     = [String]$MachineName
    [ Tags          = [String[]]$Tags ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **EnvironmentName**: The name of the pipeline environment (`AzDoPipelineEnvironment`) the resource belongs to.
- **MachineName**: The name of the machine as registered by the agent. This is how the already-installed VM resource is located; it is never used to install or register a new one.
- **Tags**: An array of tag strings, compared case-insensitively as a set, and only enforced when this property is specified.
- **Ensure**: Specifies whether the VM resource should exist. Valid values are `Present` and `Absent`.

## Additional Information

A virtual machine resource can only come into existence by an agent installing itself against the environment (`config.cmd`/`config.sh` run on the target machine) — there is no REST call that registers one, and this resource deliberately does not add one. DSC owns tags and removal of an already-registered resource, never its registration.

Registration-limit design:

- `Ensure = 'Present'` with no agent registered under `MachineName`: `Get()` reports `status = Error` with `reason = 'AgentNotRegistered'`. Because an `Error` status is still routed to `Set()` by the base class, `Set()` repeats the same check and **throws** — not `Write-Error` — so the failure cannot be silently swallowed. The message tells the operator to install the agent against this environment first.
- `Ensure = 'Absent'` with no agent registered under `MachineName`: this already is the desired state. `Get()` reports `Unchanged`/absent and `Test()` returns `$true` with no error — only a *registered* machine that should not be is something `Remove()` acts on.

Unlike the Kubernetes provider, the virtual machines provider does support an in-place tag update (`PATCH _apis/distributedtask/environments/{id}/providers/virtualmachines/{resourceId}`), so tag drift on an already-registered machine is corrected without recreating the resource or changing its id.

## Examples

## Example 1: Sample Configuration using AzDoEnvironmentVMResource Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoEnvironmentVMResource ProdVM {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            MachineName     = 'prod-vm-01'
            Tags            = @('web', 'prod')
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoEnvironmentVMResource
$properties = @{
    ProjectName     = 'MyProject'
    EnvironmentName = 'Production'
    MachineName     = 'prod-vm-01'
}

Invoke-DscResource -Name 'AzDoEnvironmentVMResource' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  EnvironmentName: Production
}

resources:
- name: Production VM Tags
  type: AzureDevOpsDscNative/AzDoEnvironmentVMResource
  dependsOn:
    - AzureDevOpsDscNative/AzDoPipelineEnvironment/Production
  properties:
    ProjectName: $ProjectName
    EnvironmentName: $EnvironmentName
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
