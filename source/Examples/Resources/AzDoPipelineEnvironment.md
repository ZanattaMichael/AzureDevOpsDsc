# DSC AzDoPipelineEnvironment Resource

# Syntax

``` PowerShell
AzDoPipelineEnvironment [string] #ResourceName
{
    ProjectName       = [String]$ProjectName
    EnvironmentName   = [String]$EnvironmentName
    [ Description     = [String]$Description ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __EnvironmentName__: The name of the pipeline environment. This is a key property.
- __Description__: An optional description for the environment.
- __Ensure__: Specifies whether the environment should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages pipeline environments in Azure DevOps. Environments represent deployment targets (e.g., Development, Staging, Production) and can be configured with approval gates and checks using the `AzDoEnvironmentApproval` and `AzDoCheckConfiguration` resources.

# Examples

## Example 1: Create a pipeline environment

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipelineEnvironment 'AddEnvironment' {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            Description     = 'Production deployment environment'
        }
    }
}
```

## Example 2: Remove a pipeline environment

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipelineEnvironment 'RemoveEnvironment' {
            Ensure          = 'Absent'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
        }
    }
}
```
