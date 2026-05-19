# DSC AzDoTaskGroup Resource

# Syntax

``` PowerShell
AzDoTaskGroup [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    TaskGroupName   = [String]$TaskGroupName
    [ Description   = [String]$Description ]
    [ Category      = [String]$Category ]
    [ Tasks         = [HashTable[]]$Tasks ]
    [ Inputs        = [HashTable[]]$Inputs ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __TaskGroupName__: The name of the task group. This is a key property.
- __Description__: An optional description for the task group.
- __Category__: The category of the task group (e.g., `Build`, `Deploy`, `Test`).
- __Tasks__: An array of task definition hashtables that form the task group.
- __Inputs__: An array of input parameter definitions for the task group.
- __Ensure__: Specifies whether the task group should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages task groups in Azure DevOps, which are reusable collections of pipeline tasks that can be shared across multiple pipelines. Task groups help enforce consistent build and deployment processes.

# Examples

## Example 1: Create a task group

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTaskGroup 'AddTaskGroup' {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            TaskGroupName = 'MyBuildTaskGroup'
            Description   = 'Reusable build steps for .NET projects'
            Category      = 'Build'
        }
    }
}
```

## Example 2: Remove a task group

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTaskGroup 'RemoveTaskGroup' {
            Ensure        = 'Absent'
            ProjectName   = 'MyProject'
            TaskGroupName = 'MyBuildTaskGroup'
        }
    }
}
```
