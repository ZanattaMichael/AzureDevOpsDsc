# DSC AzDoArtifactFeedView Resource

## Syntax

```PowerShell
AzDoArtifactFeedView [string] #ResourceName
{
    ProjectName        = [String]$ProjectName
    FeedName           = [String]$FeedName
    ViewName           = [String]$ViewName
    [ ViewType         = [String] {'release', 'implicit'} ]
    [ ViewVisibility   = [String] {'private', 'collection', 'organization', 'aadTenant'} ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **FeedName**: The name of the artifact feed that owns the view. This property is mandatory. The feed itself is managed by the `AzDoArtifactFeed` resource.
- **ViewName**: The name of the feed view. This property is mandatory.
- **ViewType**: The type of view. Valid values are `release` and `implicit`. Defaults to `release`.
- **ViewVisibility**: Who can see the view. Valid values are `private`, `collection`, `organization` and `aadTenant`. Defaults to `collection`.
- **Ensure**: Specifies whether the view should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource creates and manages views on an Azure Artifacts feed. Feed views (such as `@Release` and `@Prerelease`) let consumers pull only packages that have been promoted to a given quality level.

## Examples

## Example 1: Sample Configuration using AzDoArtifactFeedView Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoArtifactFeedView AddReleaseView {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            FeedName       = 'MyFeed'
            ViewName       = 'Release'
            ViewType       = 'release'
            ViewVisibility = 'organization'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoArtifactFeedView
$properties = @{
    ProjectName = 'MyProject'
    FeedName    = 'MyFeed'
    ViewName    = 'Release'
}

Invoke-DscResource -Name 'AzDoArtifactFeedView' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  FeedName: MyFeed
}

resources:
- name: Release Feed View
  type: AzureDevOpsDsc/AzDoArtifactFeedView
  dependsOn:
    - AzureDevOpsDsc/AzDoArtifactFeed/MyFeed
  properties:
    ProjectName: $ProjectName
    FeedName: $FeedName
    ViewName: Release
    ViewType: release
    ViewVisibility: organization
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
