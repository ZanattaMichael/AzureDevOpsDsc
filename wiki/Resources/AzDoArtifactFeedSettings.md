# AzDoArtifactFeedSettings Resource

## Description

The `AzDoArtifactFeedSettings` DSC resource is used to configure advanced settings for Azure Artifacts feeds. These settings control upstream sources (proxy feeds), package version visibility, and retention policies for artifact lifecycle management. This resource allows you to manage the operational characteristics of existing feeds including how packages are retained and sourced.

## Syntax

```powershell
AzDoArtifactFeedSettings [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    FeedName = [String] $FeedName
    [ UpstreamSources = [Hashtable[]] $UpstreamSources ]
    [ HideDeletedPackageVersions = [Boolean] $HideDeletedPackageVersions ]
    [ RetentionCountLimit = [Int32] $RetentionCountLimit ]
    [ DaysToKeepRecentlyDownloadedPackages = [Int32] $DaysToKeepRecentlyDownloadedPackages ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the project containing the artifact feed. This identifies which project's feed settings will be configured.

### Mandatory Properties

- **FeedName** [String] - The name of the artifact feed for which settings are being configured. The feed must already exist.

### Optional Properties

- **UpstreamSources** [Hashtable[]] - An array of hashtables specifying upstream feeds that this feed can proxy packages from. Each hashtable should contain:
  - `UpstreamId` - The identifier for the upstream source
  - `UpstreamUrl` - The URL of the upstream feed (e.g., https://api.nuget.org/v3/index.json for NuGet.org)
  - `DisplayName` - Display name for the upstream source
  - `AuthenticationMode` - Authentication type (e.g., 'pat', 'none', 'UsernamePassword')

- **HideDeletedPackageVersions** [Boolean] - If `$true`, deleted package versions are hidden from UI and search results. Default is `$true`. Deleted packages still exist but are not visible to users.

- **RetentionCountLimit** [Int32] - The maximum number of versions to keep per package. Set to 0 to disable retention policy. Default is `0` (not managed). Older versions are automatically deleted when exceeded.

- **DaysToKeepRecentlyDownloadedPackages** [Int32] - Number of days to keep recently downloaded packages before applying retention. Set to 0 to disable. Default is `0` (not managed). Prevents deletion of packages that have been downloaded recently.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Feed settings should be configured
  - `'Absent'` - No-op for this resource (settings are intrinsic to the feed)

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **FeedName** - The name of the feed
- **UpstreamSources** - The configured upstream sources
- **HideDeletedPackageVersions** - Whether deleted versions are hidden
- **RetentionCountLimit** - The retention count limit
- **DaysToKeepRecentlyDownloadedPackages** - Days to keep recently downloaded packages
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Configure Upstream Source for NuGet Feed

```powershell
Configuration ConfigureNuGetUpstream {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedSettings 'CompanyNuGetSettings' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            UpstreamSources = @(
                @{
                    UpstreamId = 'nuget.org'
                    UpstreamUrl = 'https://api.nuget.org/v3/index.json'
                    DisplayName = 'NuGet.org'
                    AuthenticationMode = 'none'
                }
            )
            HideDeletedPackageVersions = $true
            Ensure = 'Present'
        }
    }
}

ConfigureNuGetUpstream
Start-DscConfiguration -Path ./ConfigureNuGetUpstream -Wait -Verbose
```

### Example 2: Configure Feed with Retention Policy

```powershell
Configuration ConfigureFeedRetention {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedSettings 'FeedRetentionPolicy' {
            ProjectName = 'MyProject'
            FeedName = 'InternalPackages'
            HideDeletedPackageVersions = $true
            RetentionCountLimit = 10
            DaysToKeepRecentlyDownloadedPackages = 30
            Ensure = 'Present'
        }
    }
}

ConfigureFeedRetention
Start-DscConfiguration -Path ./ConfigureFeedRetention -Wait -Verbose
```

### Example 3: Configure Multiple Upstream Sources

```powershell
Configuration ConfigureMultipleUpstreams {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedSettings 'MultiUpstreamFeed' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            UpstreamSources = @(
                @{
                    UpstreamId = 'nuget.org'
                    UpstreamUrl = 'https://api.nuget.org/v3/index.json'
                    DisplayName = 'NuGet.org'
                    AuthenticationMode = 'none'
                },
                @{
                    UpstreamId = 'private-feed'
                    UpstreamUrl = 'https://pkgs.dev.azure.com/organization/_packaging/PrivateFeed/nuget/v3/index.json'
                    DisplayName = 'Private Feed'
                    AuthenticationMode = 'pat'
                }
            )
            HideDeletedPackageVersions = $true
            Ensure = 'Present'
        }
    }
}

ConfigureMultipleUpstreams
Start-DscConfiguration -Path ./ConfigureMultipleUpstreams -Wait -Verbose
```

### Example 4: Configure npm Feed with Upstream

```powershell
Configuration ConfigureNpmUpstream {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedSettings 'CompanyNpmSettings' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNpm'
            UpstreamSources = @(
                @{
                    UpstreamId = 'npm-registry'
                    UpstreamUrl = 'https://registry.npmjs.org/'
                    DisplayName = 'npm Registry'
                    AuthenticationMode = 'none'
                }
            )
            HideDeletedPackageVersions = $true
            RetentionCountLimit = 5
            DaysToKeepRecentlyDownloadedPackages = 30
            Ensure = 'Present'
        }
    }
}

ConfigureNpmUpstream
Start-DscConfiguration -Path ./ConfigureNpmUpstream -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Query and Update

```powershell
# Get current feed settings
$properties = @{
    ProjectName = 'MyProject'
    FeedName = 'CompanyNuGet'
}

$result = Invoke-DscResource -Name 'AzDoArtifactFeedSettings' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, FeedName, UpstreamSources, RetentionCountLimit

# Update feed settings
$setProperties = @{
    ProjectName = 'MyProject'
    FeedName = 'CompanyNuGet'
    UpstreamSources = @(
        @{
            UpstreamId = 'nuget.org'
            UpstreamUrl = 'https://api.nuget.org/v3/index.json'
            DisplayName = 'NuGet.org'
            AuthenticationMode = 'none'
        }
    )
    HideDeletedPackageVersions = $true
    RetentionCountLimit = 10
    DaysToKeepRecentlyDownloadedPackages = 30
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoArtifactFeedSettings' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Upstream Sources

- Upstream sources allow feeds to proxy packages from external feeds
- Enables single package source for applications while maintaining internal and external packages
- Requires feed to have `UpstreamEnabled = $true`
- Upstream sources vary by package type:
  - NuGet: NuGet.org, MyGet, Azure Artifacts
  - npm: npm registry, Azure Artifacts
  - Python: PyPI, Azure Artifacts
  - Maven: Maven Central, Azure Artifacts

### Retention Policy

- **RetentionCountLimit** - Maximum versions per package; older versions deleted automatically
- **DaysToKeepRecentlyDownloadedPackages** - Prevents deletion of recently accessed packages
- Retention is only active when `RetentionCountLimit > 0`
- Protects critical packages from being deleted if recently downloaded
- Useful for cleaning up old builds while preserving recent ones

### Deleted Package Versions

- `HideDeletedPackageVersions = $true` improves user experience
- Deleted packages can be restored if hidden isn't enabled
- Recommended for most feeds to reduce clutter
- Setting to `$false` shows deleted versions for advanced scenarios

### Package Consumption and Caching

- Upstream sources cache packages locally to reduce external requests
- Improves performance and reduces bandwidth usage
- Cached packages inherit upstream availability
- Authentication required only when accessing upstream

## Troubleshooting

### Issue: "Feed Not Found"

**Cause**: The specified feed does not exist in the project.

**Solution**:
```powershell
# Create the feed first using AzDoArtifactFeed resource
# Verify the feed name is correct
# Check the project scope
```

### Issue: "Upstream Source URL Invalid"

**Cause**: The upstream URL is malformed or inaccessible.

**Solution**:
```powershell
# Verify upstream URL is correct format
# Test upstream URL accessibility
# Check authentication credentials for private upstreams
# Verify firewall/network access
```

### Issue: "Retention Policy Not Applied"

**Cause**: RetentionCountLimit is 0 or retention feature not enabled.

**Solution**:
```powershell
# Set RetentionCountLimit to a value > 0
# Configure DaysToKeepRecentlyDownloadedPackages if needed
# Wait for policy to apply (may take time for existing packages)
```

## Related Resources

- [AzDoArtifactFeed](AzDoArtifactFeed.md) - Create and manage artifact feeds
- [AzDoArtifactFeedPermission](AzDoArtifactFeedPermission.md) - Manage feed permissions
- [AzDoArtifactFeedView](AzDoArtifactFeedView.md) - Create feed views
- [AzDoProject](AzDoProject.md) - Create projects containing feeds

## See Also

- [Azure Artifacts Upstream Sources](https://docs.microsoft.com/en-us/azure/devops/artifacts/upstream)
- [Azure Artifacts Package Retention](https://docs.microsoft.com/en-us/azure/devops/artifacts/feeds/package-retention)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
