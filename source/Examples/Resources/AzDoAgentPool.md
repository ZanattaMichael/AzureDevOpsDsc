# DSC AzDoAgentPool Resource

## Syntax

```PowerShell
AzDoAgentPool [string] #ResourceName
{
    PoolName          = [String]$PoolName
    [ PoolType        = [String] {'automation', 'deployment'} ]
    [ AutoProvision   = [Boolean]$AutoProvision ]
    [ AutoUpdate      = [Boolean]$AutoUpdate ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **PoolName**: The name of the agent pool. This property is mandatory and serves as the key property for the resource.
- **PoolType**: The type of agent pool. Valid values are `automation` and `deployment`. Defaults to `automation`.
- **AutoProvision**: Whether to automatically provision the agent pool to new projects. Defaults to `$false`.
- **AutoUpdate**: Whether to automatically update agents in the pool. Defaults to `$true`.
- **Ensure**: Specifies whether the agent pool should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages Azure DevOps agent pools at the organization level. Agent pools provide the infrastructure for running pipeline jobs. Pools can be shared across multiple projects.

## Examples

## Example 1: Sample Configuration using AzDoAgentPool Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAgentPool AddAgentPool {
            Ensure        = 'Present'
            PoolName      = 'MyAgentPool'
            PoolType      = 'automation'
            AutoProvision = $false
            AutoUpdate    = $true
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoAgentPool
$properties = @{
    PoolName = 'MyAgentPool'
}

Invoke-DscResource -Name 'AzDoAgentPool' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  PoolName: MyAgentPool
}

resources:
- name: My Agent Pool
  type: AzureDevOpsDsc/AzDoAgentPool
  properties:
    PoolName: $PoolName
    PoolType: automation
    AutoProvision: false
    AutoUpdate: true
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
