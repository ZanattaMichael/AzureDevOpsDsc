# DSC AzDoAreaNodes Resource

# Syntax

``` PowerShell
AzDoAreaNodes [string] #ResourceName
{
    ProjectName  = [String]$ProjectName
    [ AreaPaths  = [String[]]$AreaPaths ]
    [ Ensure     = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __AreaPaths__: An array of area path strings to create or maintain. Paths should use backslash separators relative to the project root (e.g., `MyProject\Team Alpha\Frontend`).
- __Ensure__: Specifies whether the area nodes should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages the area path hierarchy within an Azure DevOps project. Area paths are used to organize work items and can be assigned to teams to define their scope of work.

# Examples

## Example 1: Create area paths

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAreaNodes 'AddAzDoAreaNodes' {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'MyProject\Team Alpha'
                'MyProject\Team Alpha\Frontend'
                'MyProject\Team Beta'
            )
        }
    }
}
```

## Example 2: Remove all area nodes

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAreaNodes 'RemoveAzDoAreaNodes' {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
        }
    }
}
```
