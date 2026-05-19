# DSC AzDoTeamMember Resource

# Syntax

``` PowerShell
AzDoTeamMember [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    TeamName    = [String]$TeamName
    MemberName  = [String]$MemberName
    [ Ensure    = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __TeamName__: The name of the team. This is a key property.
- __MemberName__: The UPN, display name, or email of the user or group to add as a team member. This is a key property.
- __Ensure__: Specifies whether the team membership should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages membership of individual users or groups within a team. The team must already exist (use the `AzDoTeam` resource to create it first).

# Examples

## Example 1: Add a member to a team

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTeamMember 'AddTeamMember' {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            MemberName  = 'user@example.com'
        }
    }
}
```

## Example 2: Remove a member from a team

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTeamMember 'RemoveTeamMember' {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            MemberName  = 'user@example.com'
        }
    }
}
```
