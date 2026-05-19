# DSC AzDoVariableGroup Resource

# Syntax

``` PowerShell
AzDoVariableGroup [string] #ResourceName
{
    ProjectName         = [String]$ProjectName
    VariableGroupName   = [String]$VariableGroupName
    [ Description       = [String]$Description ]
    [ VariableGroupType = [String] {'Vsts', 'AzureKeyVault'} ]
    [ Variables         = [HashTable]$Variables ]
    [ AllowAccess       = [Boolean]$AllowAccess ]
    [ Ensure            = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __VariableGroupName__: The name of the variable group. This is a key property.
- __Description__: An optional description for the variable group.
- __VariableGroupType__: The type of variable group. Valid values are `Vsts` (standard) and `AzureKeyVault`. Defaults to `Vsts`.
- __Variables__: A hashtable of key-value pairs representing the variables. For secret variables, prefix the value with `secret:`.
- __AllowAccess__: Whether all pipelines can access this variable group. Defaults to `$false`.
- __Ensure__: Specifies whether the variable group should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages variable groups in Azure DevOps, allowing shared variables and secrets to be used across multiple pipelines.

# Examples

## Example 1: Create a variable group

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoVariableGroup 'AddVariableGroup' {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            Description       = 'Shared pipeline variables'
            VariableGroupType = 'Vsts'
            AllowAccess       = $true
            Variables         = @{
                APP_ENV       = 'production'
                APP_LOG_LEVEL = 'warn'
            }
        }
    }
}
```

## Example 2: Remove a variable group

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoVariableGroup 'RemoveVariableGroup' {
            Ensure            = 'Absent'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
        }
    }
}
```
