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
    [ SharedWithProjects  = [String[]]$SharedWithProjects ]
    [ SharedNameOverrides = [HashTable]$SharedNameOverrides ]
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
- **SharedWithProjects**: Names of other projects to share this service connection with, in
  addition to `ProjectName`. Sharing is only compared and enforced when this property is
  set; a configuration that omits it leaves any existing sharing untouched. Dropping a
  project from this list unshares the connection from it without deleting it.
- **SharedNameOverrides**: A hashtable of `ProjectName = DisplayName` giving the service
  connection a different name in a shared project. Only takes effect for names in
  `SharedWithProjects`; the owning project's reference always uses `ConnectionName`.
- **Ensure**: Specifies whether the service connection should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages service connections in Azure DevOps, enabling pipelines to connect to external services such as Azure subscriptions, GitHub repositories, or Kubernetes clusters.

Removing a shared service connection from its owning project removes it from every project
it is shared with — Azure DevOps has no operation to hand ownership to another project
instead. `Remove-AzDoServiceConnection` warns and names the other projects when this
applies, but still proceeds; unshare the projects you want to keep it available to first
(set `SharedWithProjects` to just the ones that should keep it, or empty it out) if that is
not what you want.

Permissions set via `AzDoServiceConnectionPermission` are unaffected by sharing: the ACL
token is anchored to the owning project and the service connection's own id, regardless of
how many other projects it is shared with.

## Examples

## Example 1: Sample Configuration using AzDoServiceConnection Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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

Invoke-DscResource -Name 'AzDoServiceConnection' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sharing a service connection with another project

``` PowerShell
Configuration ExampleSharedConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoServiceConnection ShareServiceConnection {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            ConnectionName      = 'MyAzureConnection'
            ConnectionType      = 'AzureRM'
            Authorization       = @{
                tenantId           = '00000000-0000-0000-0000-000000000000'
                servicePrincipalId = '00000000-0000-0000-0000-000000000001'
                authenticationType = 'spnKey'
            }
            Data                = @{
                subscriptionId   = '00000000-0000-0000-0000-000000000002'
                subscriptionName = 'My Azure Subscription'
            }
            SharedWithProjects  = @('OtherProject')
            SharedNameOverrides = @{
                OtherProject = 'MyAzureConnection (from MyProject)'
            }
        }
    }
}

Start-DscConfiguration -Path ./ExampleSharedConfig -Wait -Verbose
```

## Example 4: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  ConnectionName: MyAzureConnection
}

resources:
- name: Azure Service Connection
  type: AzureDevOpsDscNative/AzDoServiceConnection
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
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
