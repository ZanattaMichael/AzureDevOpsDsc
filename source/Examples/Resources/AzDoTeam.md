# DSC AzDoTeam Resource

# Syntax

``` PowerShell
AzDoTeam [string] #ResourceName
{
    ProjectName   = [String]$ProjectName
    TeamName      = [String]$TeamName
    [ Description = [String]$Description ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __TeamName__: The name of the team. This is a key property.
- __Description__: An optional description for the team.
- __Ensure__: Specifies whether the team should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages teams within Azure DevOps projects. Teams group users together and can be assigned area paths and iterations for work item organization. Team members can be managed separately using the `AzDoTeamMember` resource.

# Examples

## Example 1: Create a team

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTeam 'AddTeam' {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            Description = 'Team responsible for frontend development'
        }
    }
}
```

## Example 2: Remove a team

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTeam 'RemoveTeam' {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
        }
    }
}
```
