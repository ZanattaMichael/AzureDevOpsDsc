# DSC AzDoServiceConnection Resource

## Syntax

```PowerShell
AzDoServiceConnection [string] #ResourceName
{
    ProjectName         = [String]$ProjectName
    ConnectionName      = [String]$ConnectionName
    ConnectionType      = [String]$ConnectionType
    [ Description       = [String]$Description ]
    [ AllowAllPipelines = [Boolean]$AllowAllPipelines ]
    [ Authorization     = [HashTable]$Authorization ]
    [ Data              = [HashTable]$Data ]
    [ Ensure            = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **ConnectionName**: The name of the service connection. This is a key property.
- **ConnectionType**: The type of service connection (e.g., `AzureRM`, `GitHub`, `Kubernetes`). This is a mandatory property.
- **Description**: An optional description for the service connection.
- **AllowAllPipelines**: Whether all pipelines can use this service connection. Defaults to `$false`.
- **Authorization**: A hashtable of authorization parameters specific to the connection type.
- **Data**: A hashtable of additional data parameters specific to the connection type.
- **Ensure**: Specifies whether the service connection should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages service connections in Azure DevOps, enabling pipelines to connect to external services such as Azure subscriptions, GitHub repositories, or Kubernetes clusters.

## Examples

## Example 1: Sample Configuration using AzDoServiceConnection Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoServiceConnection AddServiceConnection {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            ConnectionName   = 'MyAzureConnection'
            ConnectionType   = 'AzureRM'
            Description      = 'Connection to Azure subscription'
            AllowAllPipelines = $true
            Authorization    = @{
                tenantId           = '00000000-0000-0000-0000-000000000000'
                servicePrincipalId = '00000000-0000-0000-0000-000000000001'
                authenticationType = 'spnKey'
            }
            Data             = @{
                subscriptionId   = '00000000-0000-0000-0000-000000000002'
                subscriptionName = 'My Azure Subscription'
            }
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoServiceConnection
$properties = @{
    ProjectName    = 'MyProject'
    ConnectionName = 'MyAzureConnection'
    ConnectionType = 'AzureRM'
}

Invoke-DscResource -Name 'AzDoServiceConnection' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  ConnectionName: MyAzureConnection
}

resources:
- name: Azure Service Connection
  type: AzureDevOpsDsc/AzDoServiceConnection
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    ConnectionName: $ConnectionName
    ConnectionType: AzureRM
    Description: Connection to Azure subscription
    AllowAllPipelines: true
    Authorization:
      tenantId: '00000000-0000-0000-0000-000000000000'
      servicePrincipalId: '00000000-0000-0000-0000-000000000001'
      authenticationType: spnKey
    Data:
      subscriptionId: '00000000-0000-0000-0000-000000000002'
      subscriptionName: My Azure Subscription
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
