# AzDoArtifactFeed Resource

## Description

The `AzDoArtifactFeed` DSC resource is used to create and manage artifact feeds in Azure Artifacts. Artifact feeds are package repositories that store and distribute software packages (NuGet, npm, Python, etc.). This resource allows you to define and enforce the desired state of feeds, including whether they are project-scoped or organization-scoped, and to configure their features like upstream sources and package version visibility.

## Syntax

```powershell
AzDoArtifactFeed [string] #ResourceName
{
    FeedName = [String] $FeedName
    [ ProjectName = [String] $ProjectName ]
    [ Description = [String] $Description ]
    [ BadgesEnabled = [Boolean] $BadgesEnabled ]
    [ HideDeletedPackageVersions = [Boolean] $HideDeletedPackageVersions ]
    [ UpstreamEnabled = [Boolean] $UpstreamEnabled ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **FeedName** [String] - The name of the artifact feed. This must be unique within the project (if project-scoped) or organization (if organization-scoped).

### Optional Properties

- **ProjectName** [String] - The name of the project if this is a project-scoped feed. When omitted, the feed is organization-scoped. Default is `$null`.

- **Description** [String] - A description of the feed explaining its purpose, package types, or intended users. Default is empty string.

- **BadgesEnabled** [Boolean] - If `$true`, allows the feed to display public badges for package status and metadata. Default is `$false`.

- **HideDeletedPackageVersions** [Boolean] - If `$true`, deleted package versions are hidden from search results and package listings. Default is `$true`.

- **UpstreamEnabled** [Boolean] - If `$true`, enables upstream sources which allow the feed to proxy packages from external feeds (NuGet.org, npm registry, etc.). Default is `$true`.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Artifact feed should exist
  - `'Absent'` - Artifact feed should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **FeedName** - The name of the feed
- **ProjectName** - The project name (if project-scoped)
- **Description** - The feed description
- **BadgesEnabled** - Whether badges are enabled
- **HideDeletedPackageVersions** - Whether deleted versions are hidden
- **UpstreamEnabled** - Whether upstream sources are enabled
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create an Organization-Scoped Artifact Feed

```powershell
Configuration CreateOrgScopedFeed {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeed 'CompanyNuGetFeed' {
            FeedName = 'CompanyNuGet'
            Description = 'Organization-wide NuGet package repository'
            BadgesEnabled = $true
            HideDeletedPackageVersions = $true
            UpstreamEnabled = $true
            Ensure = 'Present'
        }
    }
}

CreateOrgScopedFeed
Start-DscConfiguration -Path ./CreateOrgScopedFeed -Wait -Verbose
```

### Example 2: Create a Project-Scoped Artifact Feed

```powershell
Configuration CreateProjectScopedFeed {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeed 'ProjectSpecificFeed' {
            FeedName = 'ProjectPackages'
            ProjectName = 'MyProject'
            Description = 'Project-specific internal packages'
            BadgesEnabled = $false
            HideDeletedPackageVersions = $true
            UpstreamEnabled = $true
            Ensure = 'Present'
        }
    }
}

CreateProjectScopedFeed
Start-DscConfiguration -Path ./CreateProjectScopedFeed -Wait -Verbose
```

### Example 3: Create Multiple Feeds with Different Configurations

```powershell
Configuration CreateMultipleFeeds {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Public NuGet feed with upstream enabled
        AzDoArtifactFeed 'PublicNuGetFeed' {
            FeedName = 'PublicPackages'
            Description = 'Public NuGet packages with upstream proxy'
            BadgesEnabled = $true
            HideDeletedPackageVersions = $false
            UpstreamEnabled = $true
            Ensure = 'Present'
        }
        
        # npm feed for JavaScript packages
        AzDoArtifactFeed 'CompanyNpmFeed' {
            FeedName = 'CompanyNpm'
            Description = 'Internal npm packages'
            BadgesEnabled = $true
            HideDeletedPackageVersions = $true
            UpstreamEnabled = $true
            Ensure = 'Present'
        }
        
        # Project-specific Python packages
        AzDoArtifactFeed 'ProjectPythonFeed' {
            FeedName = 'ProjectPython'
            ProjectName = 'DataScience'
            Description = 'Project Python dependencies and packages'
            BadgesEnabled = $false
            HideDeletedPackageVersions = $true
            UpstreamEnabled = $false
            Ensure = 'Present'
        }
    }
}

CreateMultipleFeeds
Start-DscConfiguration -Path ./CreateMultipleFeeds -Wait -Verbose
```

### Example 4: Create Feed without Upstream Support

```powershell
Configuration CreateInternalOnlyFeed {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeed 'InternalOnlyFeed' {
            FeedName = 'InternalPackagesOnly'
            Description = 'Internal packages only - no upstream proxy'
            BadgesEnabled = $false
            HideDeletedPackageVersions = $true
            UpstreamEnabled = $false
            Ensure = 'Present'
        }
    }
}

CreateInternalOnlyFeed
Start-DscConfiguration -Path ./CreateInternalOnlyFeed -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Query and Create

```powershell
# Get current feed state
$properties = @{
    FeedName = 'CompanyNuGet'
}

$result = Invoke-DscResource -Name 'AzDoArtifactFeed' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object FeedName, Description, BadgesEnabled, UpstreamEnabled

# Create a new feed
$setProperties = @{
    FeedName = 'NewFeed'
    Description = 'New artifact feed'
    BadgesEnabled = $true
    HideDeletedPackageVersions = $true
    UpstreamEnabled = $true
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoArtifactFeed' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Feed Scope

- **Organization-Scoped**: When `ProjectName` is omitted, the feed is available organization-wide
- **Project-Scoped**: When `ProjectName` is specified, the feed is only available within that project
- Scope affects visibility, permissions, and feed lifecycle management
- Organization feeds provide centralized package management; project feeds provide isolation

### Package Types

- Feeds can contain multiple package types: NuGet, npm, Python, Maven, etc.
- Type restrictions can be configured separately through feed settings
- Upstream sources vary by package type (NuGet.org for NuGet, npm registry for npm, etc.)

### Upstream Sources

- When `UpstreamEnabled = $true`, the feed can proxy packages from external sources
- Reduces bandwidth by caching external packages internally
- Requires separate configuration of upstream sources using `AzDoArtifactFeedSettings`
- Useful for both public (NuGet.org) and private upstream feeds

### Deleted Versions

- `HideDeletedPackageVersions = $true` improves user experience by hiding obsolete versions
- Deleted packages still exist; they're just hidden from searches
- Can be reverted if specific old versions need to be restored
- Recommended for reducing clutter in package listings

### Badges

- Badges provide package status information for external documentation
- Requires authentication when `BadgesEnabled = $false`
- Useful for publishing package availability to internal documentation
- Can expose package version information if public

## Troubleshooting

### Issue: "Feed Name Already Exists"

**Cause**: A feed with the same name already exists in the scope (organization or project).

**Solution**:
```powershell
# Use a different feed name
# Or use Ensure = 'Present' which is idempotent if the feed exists
# Check existing feeds in Azure Artifacts
```

### Issue: "Cannot Create Feed - Insufficient Permissions"

**Cause**: Authentication account lacks permission to create feeds.

**Solution**:
```powershell
# Verify account has feed creation permissions
# Check project or organization administrator roles
# Ensure Personal Access Token has appropriate scopes
```

### Issue: "Project Not Found"

**Cause**: Specified project does not exist when creating project-scoped feed.

**Solution**:
```powershell
# Create the project first using AzDoProject resource
# Verify the project name is correct
# Ensure the project scope is correct
```

## Related Resources

- [AzDoArtifactFeedPermission](AzDoArtifactFeedPermission.md) - Manage feed permissions
- [AzDoArtifactFeedSettings](AzDoArtifactFeedSettings.md) - Configure feed settings and retention
- [AzDoArtifactFeedView](AzDoArtifactFeedView.md) - Create views within feeds
- [AzDoProject](AzDoProject.md) - Create projects that host feeds

## See Also

- [Azure Artifacts Documentation](https://docs.microsoft.com/en-us/azure/devops/artifacts)
- [Azure Artifacts Feeds](https://docs.microsoft.com/en-us/azure/devops/artifacts/concepts/feeds)
- [Azure Artifacts Upstream Sources](https://docs.microsoft.com/en-us/azure/devops/artifacts/upstream)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
