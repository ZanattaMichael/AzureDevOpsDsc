# DSC AzDoIterationNodes Resource

# Syntax

``` PowerShell
AzDoIterationNodes [string] #ResourceName
{
    ProjectName              = [String]$ProjectName
    [ IterationAttributes    = [HashTable[]]$IterationAttributes ]
    [ Ensure                 = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __IterationAttributes__: An array of hashtables defining iterations (sprints). Each hashtable can include `Name`, `StartDate`, and `FinishDate`.
- __Ensure__: Specifies whether the iteration nodes should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## IterationAttributes Syntax

``` PowerShell
AzDoIterationNodes/IterationAttributes
{
    Name       = [String]$IterationName
    StartDate  = [String]$StartDate    # Format: 'yyyy-MM-dd'
    FinishDate = [String]$FinishDate   # Format: 'yyyy-MM-dd'
}
```

# Additional Information

This resource manages the iteration (sprint) hierarchy within an Azure DevOps project. Iterations define time-boxed development cycles and can be configured with start and end dates to support sprint planning.

# Examples

## Example 1: Create sprint iterations

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoIterationNodes 'AddAzDoIterationNodes' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            IterationAttributes = @(
                @{
                    Name       = 'Sprint 1'
                    StartDate  = '2024-01-01'
                    FinishDate = '2024-01-14'
                }
                @{
                    Name       = 'Sprint 2'
                    StartDate  = '2024-01-15'
                    FinishDate = '2024-01-28'
                }
            )
        }
    }
}
```

## Example 2: Remove all iteration nodes

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoIterationNodes 'RemoveAzDoIterationNodes' {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
        }
    }
}
```
