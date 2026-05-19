# DSC AzDoCheckConfiguration Resource

# Syntax

``` PowerShell
AzDoCheckConfiguration [string] #ResourceName
{
    ProjectName          = [String]$ProjectName
    ResourceName         = [String]$ResourceName
    ResourceType         = [String] {'environment', 'repository', 'endpoint'}
    CheckType            = [String]$CheckType
    [ Settings           = [HashTable]$Settings ]
    [ TimeoutInMinutes   = [UInt32]$TimeoutInMinutes ]
    [ Enabled            = [Boolean]$Enabled ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __ResourceName__: The name of the resource to attach the check to (environment name, repository name, or service connection name). This is a key property.
- __ResourceType__: The type of resource. Valid values are `environment`, `repository`, and `endpoint`. This is a key property.
- __CheckType__: The type of check to configure (e.g., `Task Check`, `Approval`, `ExclusiveLock`). This is a key property.
- __Settings__: A hashtable of check-specific configuration settings.
- __TimeoutInMinutes__: How long the check can run before timing out. Defaults to `43200` (30 days).
- __Enabled__: Whether the check is active. Defaults to `$true`.
- __Ensure__: Specifies whether the check should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages pipeline check configurations on Azure DevOps resources such as environments, repositories, and service connections. Checks enforce gates that must pass before a pipeline can access the protected resource.

Common check types include:
- **Task Check** - Runs a custom task as a gate
- **Approval** - Requires manual approval (use `AzDoEnvironmentApproval` for environment approvals)
- **ExclusiveLock** - Ensures only one pipeline run accesses the resource at a time

# Examples

## Example 1: Add an exclusive lock check on an environment

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoCheckConfiguration 'AddExclusiveLock' {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            ResourceName     = 'Production'
            ResourceType     = 'environment'
            CheckType        = 'ExclusiveLock'
            TimeoutInMinutes = 43200
            Enabled          = $true
        }
    }
}
```

## Example 2: Add a task check on a service connection

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoCheckConfiguration 'AddTaskCheck' {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            ResourceName     = 'MyAzureServiceConnection'
            ResourceType     = 'endpoint'
            CheckType        = 'Task Check'
            TimeoutInMinutes = 1440
            Enabled          = $true
            Settings         = @{
                displayName   = 'Validate requester'
                definitionRef = @{
                    id      = '9a2b4d5e-1234-5678-abcd-9876543210ef'
                    name    = 'PowerShell'
                    version = '2.*'
                }
                inputs        = @{
                    script = 'Write-Host "Authorization validated"'
                }
            }
        }
    }
}
```
