# DSC AzDoArtifactFeedSettings Resource

## Syntax

```PowerShell
AzDoArtifactFeedSettings [string] #ResourceName
{
    ProjectName                            = [String]$ProjectName
    FeedName                               = [String]$FeedName
    [ UpstreamSources                      = [String[]]$UpstreamSources ]
    [ HideDeletedPackageVersions           = [Boolean]$HideDeletedPackageVersions ]
    [ RetentionCountLimit                  = [Int32]$RetentionCountLimit ]
    [ DaysToKeepRecentlyDownloadedPackages = [Int32]$DaysToKeepRecentlyDownloadedPackages ]
    [ Ensure                               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **FeedName**: The name of the artifact feed whose settings are managed. This property is mandatory. The feed itself is managed by the `AzDoArtifactFeed` resource.
- **UpstreamSources**: The upstream sources configured on the feed. Only applied when supplied (a null/empty value leaves the existing upstream sources unchanged).
- **HideDeletedPackageVersions**: Whether deleted package versions are hidden. Defaults to `$true`.
- **RetentionCountLimit**: The maximum number of versions to retain per package. A value of `0` (the default) means the retention policy is not managed by this resource.
- **DaysToKeepRecentlyDownloadedPackages**: The number of days to keep recently downloaded packages, used with the retention policy.
- **Ensure**: Specifies the desired state. Feed settings cannot be removed, so `Absent` is a no-op.

## Additional Information

This resource configures settings on an existing Azure Artifacts feed: upstream sources, whether deleted package versions are hidden, and the retention policy. Because feed settings cannot be deleted, `Ensure = 'Absent'` is treated as a no-op.

## Examples

## Example 1: Sample Configuration using AzDoArtifactFeedSettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoArtifactFeedSettings ConfigureFeed {
            Ensure                               = 'Present'
            ProjectName                          = 'MyProject'
            FeedName                             = 'MyFeed'
            HideDeletedPackageVersions           = $true
            RetentionCountLimit                  = 100
            DaysToKeepRecentlyDownloadedPackages = 30
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoArtifactFeedSettings
$properties = @{
    ProjectName = 'MyProject'
    FeedName    = 'MyFeed'
}

Invoke-DscResource -Name 'AzDoArtifactFeedSettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  FeedName: MyFeed
}

resources:
- name: Configure Feed Settings
  type: AzureDevOpsDsc/AzDoArtifactFeedSettings
  dependsOn:
    - AzureDevOpsDsc/AzDoArtifactFeed/MyFeed
  properties:
    ProjectName: $ProjectName
    FeedName: $FeedName
    HideDeletedPackageVersions: true
    RetentionCountLimit: 100
    DaysToKeepRecentlyDownloadedPackages: 30
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
