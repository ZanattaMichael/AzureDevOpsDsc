# DSC AzDoServiceConnection Resource

# Syntax

``` PowerShell
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

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __ConnectionName__: The name of the service connection. This is a key property.
- __ConnectionType__: The type of service connection (e.g., `AzureRM`, `GitHub`, `Kubernetes`). This is a mandatory property.
- __Description__: An optional description for the service connection.
- __AllowAllPipelines__: Whether all pipelines can use this service connection. Defaults to `$false`.
- __Authorization__: A hashtable of authorization parameters specific to the connection type.
- __Data__: A hashtable of additional data parameters specific to the connection type.
- __Ensure__: Specifies whether the service connection should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Authorization Examples by ConnectionType

### AzureRM (Service Principal)
``` PowerShell
Authorization = @{
    tenantId           = 'your-tenant-id'
    servicePrincipalId = 'your-sp-client-id'
    authenticationType = 'spnKey'
}
Data = @{
    subscriptionId   = 'your-subscription-id'
    subscriptionName = 'My Azure Subscription'
}
```

# Additional Information

This resource manages service connections in Azure DevOps, enabling pipelines to connect to external services such as Azure subscriptions, GitHub repositories, or Kubernetes clusters.

# Examples

## Example 1: Create an Azure RM service connection

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoServiceConnection 'AddServiceConnection' {
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
```

## Example 2: Remove a service connection

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoServiceConnection 'RemoveServiceConnection' {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureConnection'
            ConnectionType = 'AzureRM'
        }
    }
}
```
