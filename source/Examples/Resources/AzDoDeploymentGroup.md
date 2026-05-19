# DSC AzDoDeploymentGroup Resource

# Syntax

``` PowerShell
AzDoDeploymentGroup [string] #ResourceName
{
    ProjectName           = [String]$ProjectName
    DeploymentGroupName   = [String]$DeploymentGroupName
    [ Description         = [String]$Description ]
    [ Tags                = [String[]]$Tags ]
    [ Ensure              = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __DeploymentGroupName__: The name of the deployment group. This is a key property.
- __Description__: An optional description for the deployment group.
- __Tags__: An array of tag strings to associate with the deployment group for filtering and targeting.
- __Ensure__: Specifies whether the deployment group should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages Azure DevOps deployment groups, which are collections of physical or virtual machines used as deployment targets for classic release pipelines. Agents installed on these machines register with the deployment group to receive deployments.

# Examples

## Example 1: Create a deployment group

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoDeploymentGroup 'AddDeploymentGroup' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
            Description         = 'Deployment group for production web servers'
            Tags                = @('Production', 'Windows', 'IIS')
        }
    }
}
```

## Example 2: Remove a deployment group

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoDeploymentGroup 'RemoveDeploymentGroup' {
            Ensure              = 'Absent'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
        }
    }
}
```
