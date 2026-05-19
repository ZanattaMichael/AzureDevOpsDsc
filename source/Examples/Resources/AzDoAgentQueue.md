# DSC AzDoAgentQueue Resource

# Syntax

``` PowerShell
AzDoAgentQueue [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    QueueName   = [String]$QueueName
    PoolName    = [String]$PoolName
    [ Ensure    = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __QueueName__: The name of the agent queue within the project. This is a key property.
- __PoolName__: The name of the agent pool that backs this queue. This is a mandatory property.
- __Ensure__: Specifies whether the agent queue should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages agent queues within Azure DevOps projects. An agent queue is the project-level reference to an organization-level agent pool, allowing pipelines in the project to use that pool.

# Examples

## Example 1: Create an Agent Queue

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAgentQueue 'AddAgentQueue' {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            QueueName   = 'MyQueue'
            PoolName    = 'MyAgentPool'
        }
    }
}
```

## Example 2: Remove an Agent Queue

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAgentQueue 'RemoveAgentQueue' {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            QueueName   = 'MyQueue'
            PoolName    = 'MyAgentPool'
        }
    }
}
```
