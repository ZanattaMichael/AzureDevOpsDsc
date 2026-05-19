# DSC AzDoArtifactFeedPermission Resource

# Syntax

``` PowerShell
AzDoArtifactFeedPermission [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    FeedName    = [String]$FeedName
    Permissions = [HashTable[]]$Permissions
    [ Ensure    = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __FeedName__: The name of the artifact feed. This is a key property.
- __Permissions__: An array of permission hashtables specifying role-based access for identities.
- __Ensure__: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permissions Syntax

``` PowerShell
AzDoArtifactFeedPermission/Permissions
{
    identity = [String]$Identity   # Descriptor or display name of the identity
    role     = [String] {'Reader', 'Contributor', 'Collaborator', 'Administrator'}
}
```

## Role List

| Role | Description |
| ---- | ----------- |
| Reader | Can download and view packages |
| Contributor | Can publish and promote packages |
| Collaborator | Can save packages from upstream sources |
| Administrator | Full control including managing permissions |

# Additional Information

This resource manages role-based permissions on Azure Artifacts feeds, controlling which users or groups can read, publish, or administer packages.

# Examples

## Example 1: Grant permissions on an Artifact Feed

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoArtifactFeedPermission 'AddArtifactFeedPermission' {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            FeedName    = 'MyFeed'
            Permissions = @(
                @{ identity = '[MyProject]\Contributors'; role = 'Contributor' }
                @{ identity = '[MyProject]\Readers'; role = 'Reader' }
            )
        }
    }
}
```
