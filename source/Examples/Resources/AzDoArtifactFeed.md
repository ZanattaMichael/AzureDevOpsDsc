# DSC AzDoArtifactFeed Resource

## Syntax

```PowerShell
AzDoArtifactFeed [string] #ResourceName
{
    FeedName          = [String]$FeedName
    [ ProjectName     = [String]$ProjectName ]
    [ Description     = [String]$Description ]
    [ BadgesEnabled   = [Boolean]$BadgesEnabled ]
    [ UpstreamEnabled = [Boolean]$UpstreamEnabled ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **FeedName**: The name of the artifact feed. This property is mandatory and is the key property for the resource.
- **ProjectName**: The name of the Azure DevOps project. **Optional** — when supplied, the feed is **project-scoped**; when omitted, the feed is **organization-scoped**.
- **Description**: An optional description for the feed.
- **BadgesEnabled**: Whether to enable badges for the feed. Defaults to `$false`.
- **UpstreamEnabled**: Whether to enable upstream sources. Defaults to `$true`.
- **Ensure**: Specifies whether the feed should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages Azure Artifacts feeds. A feed can be **project-scoped** (set `ProjectName`) or **organization-scoped** (omit `ProjectName`). Artifact feeds allow teams to share packages (NuGet, npm, Maven, Python, Universal Packages).

## Examples

## Example 1: Sample Configuration using AzDoArtifactFeed Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoArtifactFeed AddArtifactFeed {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            FeedName        = 'MyFeed'
            Description     = 'My package feed'
            BadgesEnabled   = $false
            UpstreamEnabled = $true
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 1b: Organization-scoped feed (omit ProjectName)

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoArtifactFeed AddOrgFeed {
            Ensure      = 'Present'
            FeedName    = 'SharedOrgFeed'
            Description = 'Organization-wide package feed'
            # No ProjectName -> the feed is created at the organization scope.
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoArtifactFeed
$properties = @{
    ProjectName = 'MyProject'
    FeedName    = 'MyFeed'
}

Invoke-DscResource -Name 'AzDoArtifactFeed' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  FeedName: MyFeed
}

resources:
- name: My Artifact Feed
  type: AzureDevOpsDsc/AzDoArtifactFeed
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    FeedName: $FeedName
    Description: My package feed
    BadgesEnabled: false
    UpstreamEnabled: true
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
