# DSC AzDoArtifactFeed Resource

# Syntax

``` PowerShell
AzDoArtifactFeed [string] #ResourceName
{
    ProjectName       = [String]$ProjectName
    FeedName          = [String]$FeedName
    [ Description     = [String]$Description ]
    [ BadgesEnabled   = [Boolean]$BadgesEnabled ]
    [ UpstreamEnabled = [Boolean]$UpstreamEnabled ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __FeedName__: The name of the artifact feed. This is a key property.
- __Description__: An optional description for the feed.
- __BadgesEnabled__: Whether to enable badges for the feed. Defaults to `$false`.
- __UpstreamEnabled__: Whether to enable upstream sources. Defaults to `$true`.
- __Ensure__: Specifies whether the feed should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages Azure Artifacts feeds within a project. Artifact feeds allow teams to share packages (NuGet, npm, Maven, Python, Universal Packages) across the organization.

# Examples

## Example 1: Create an Artifact Feed

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoArtifactFeed 'AddArtifactFeed' {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            FeedName        = 'MyFeed'
            Description     = 'My package feed'
            BadgesEnabled   = $false
            UpstreamEnabled = $true
        }
    }
}
```

## Example 2: Remove an Artifact Feed

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoArtifactFeed 'RemoveArtifactFeed' {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            FeedName    = 'MyFeed'
        }
    }
}
```
