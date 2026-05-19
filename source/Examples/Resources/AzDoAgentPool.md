# DSC AzDoAgentPool Resource

# Syntax

``` PowerShell
AzDoAgentPool [string] #ResourceName
{
    PoolName      = [String]$PoolName
    [ PoolType    = [String] {'automation', 'deployment'} ]
    [ AutoProvision = [Boolean]$AutoProvision ]
    [ AutoUpdate  = [Boolean]$AutoUpdate ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __PoolName__: The name of the agent pool. This is a key property.
- __PoolType__: The type of agent pool. Valid values are `automation` and `deployment`. Defaults to `automation`.
- __AutoProvision__: Whether to automatically provision the agent pool to new projects. Defaults to `$false`.
- __AutoUpdate__: Whether to automatically update agents in the pool. Defaults to `$true`.
- __Ensure__: Specifies whether the agent pool should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages Azure DevOps agent pools at the organization level. Agent pools provide the infrastructure for running pipeline jobs.

# Examples

## Example 1: Create an Agent Pool

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAgentPool 'AddAgentPool' {
            Ensure        = 'Present'
            PoolName      = 'MyAgentPool'
            PoolType      = 'automation'
            AutoProvision = $false
            AutoUpdate    = $true
        }
    }
}
```

## Example 2: Remove an Agent Pool

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAgentPool 'RemoveAgentPool' {
            Ensure   = 'Absent'
            PoolName = 'MyAgentPool'
        }
    }
}
```
