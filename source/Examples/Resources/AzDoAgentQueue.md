# DSC AzDoAgentQueue Resource

## Syntax

```PowerShell
AzDoAgentQueue [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    QueueName   = [String]$QueueName
    PoolName    = [String]$PoolName
    [ Ensure    = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **QueueName**: The name of the agent queue within the project. This is a key property.
- **PoolName**: The name of the agent pool that backs this queue. This is a mandatory property.
- **Ensure**: Specifies whether the agent queue should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages agent queues within Azure DevOps projects. An agent queue is the project-level reference to an organization-level agent pool, allowing pipelines in the project to use that pool.

## Examples

## Example 1: Sample Configuration using AzDoAgentQueue Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAgentQueue AddAgentQueue {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            QueueName   = 'MyQueue'
            PoolName    = 'MyAgentPool'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoAgentQueue
$properties = @{
    ProjectName = 'MyProject'
    QueueName   = 'MyQueue'
    PoolName    = 'MyAgentPool'
}

Invoke-DscResource -Name 'AzDoAgentQueue' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  QueueName: MyQueue,
  PoolName: MyAgentPool
}

resources:
- name: My Agent Queue
  type: AzureDevOpsDsc/AzDoAgentQueue
  dependsOn:
    - AzureDevOpsDsc/AzDoAgentPool/MyAgentPool
  properties:
    ProjectName: $ProjectName
    QueueName: $QueueName
    PoolName: $PoolName
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
