# AzDoArtifactFeedView Resource

## Description

The `AzDoArtifactFeedView` DSC resource is used to create and manage views on Azure Artifacts feeds. Views provide filtered access to packages in a feed, allowing you to control package visibility and lifecycle (e.g., marking packages as "released" vs "pre-release"). Views are commonly used to promote packages through stages or control which packages are available to different consumers.

## Syntax

```powershell
AzDoArtifactFeedView [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    FeedName = [String] $FeedName
    ViewName = [String] $ViewName
    [ ViewType = [String] {'release', 'implicit'} ]
    [ ViewVisibility = [String] {'private', 'collection', 'organization', 'aadTenant'} ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the project containing the artifact feed.

### Mandatory Properties

- **FeedName** [String] - The name of the artifact feed for which the view is being created. The feed must already exist.

- **ViewName** [String] - The name of the view within the feed. Common names include 'Release', 'PreRelease', 'Snapshot', or custom names representing pipeline stages.

### Optional Properties

- **ViewType** [String] - The type of view determining package promotion behavior:
  - `'release'` - A release view where packages must be explicitly added; typically used for stable versions
  - `'implicit'` - An implicit view that automatically includes packages matching criteria
  - Default is `'release'`

- **ViewVisibility** [String] - The visibility scope of the view:
  - `'private'` - Visible only to the creator and those with explicit permissions
  - `'collection'` - Visible to all users in the project collection
  - `'organization'` - Visible to all users in the organization
  - `'aadTenant'` - Visible to all users in the Azure AD tenant
  - Default is `'collection'`

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Feed view should exist
  - `'Absent'` - Feed view should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **FeedName** - The name of the feed
- **ViewName** - The name of the view
- **ViewType** - The type of view
- **ViewVisibility** - The visibility scope of the view
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create a Release View in NuGet Feed

```powershell
Configuration CreateReleaseView {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedView 'ReleaseView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            ViewName = 'Release'
            ViewType = 'release'
            ViewVisibility = 'collection'
            Ensure = 'Present'
        }
    }
}

CreateReleaseView
Start-DscConfiguration -Path ./CreateReleaseView -Wait -Verbose
```

### Example 2: Create Multiple Views for Package Lifecycle

```powershell
Configuration CreatePackageLifecycleViews {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Pre-release view for development packages
        AzDoArtifactFeedView 'PreReleaseView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            ViewName = 'PreRelease'
            ViewType = 'release'
            ViewVisibility = 'private'
            Ensure = 'Present'
        }
        
        # Release view for stable packages
        AzDoArtifactFeedView 'ReleaseView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            ViewName = 'Release'
            ViewType = 'release'
            ViewVisibility = 'collection'
            Ensure = 'Present'
            DependsOn = '[AzDoArtifactFeedView]PreReleaseView'
        }
        
        # Legacy view for deprecated packages
        AzDoArtifactFeedView 'LegacyView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            ViewName = 'Legacy'
            ViewType = 'release'
            ViewVisibility = 'private'
            Ensure = 'Present'
            DependsOn = '[AzDoArtifactFeedView]ReleaseView'
        }
    }
}

CreatePackageLifecycleViews
Start-DscConfiguration -Path ./CreatePackageLifecycleViews -Wait -Verbose
```

### Example 3: Create Views with Different Visibility Levels

```powershell
Configuration CreateViewsWithDifferentVisibility {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Private view for internal development
        AzDoArtifactFeedView 'PrivateDevelopmentView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            ViewName = 'Development'
            ViewType = 'release'
            ViewVisibility = 'private'
            Ensure = 'Present'
        }
        
        # Collection view for all projects in collection
        AzDoArtifactFeedView 'CollectionView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            ViewName = 'Shared'
            ViewType = 'release'
            ViewVisibility = 'collection'
            Ensure = 'Present'
        }
        
        # Organization view for all teams
        AzDoArtifactFeedView 'OrganizationView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNuGet'
            ViewName = 'Public'
            ViewType = 'release'
            ViewVisibility = 'organization'
            Ensure = 'Present'
        }
    }
}

CreateViewsWithDifferentVisibility
Start-DscConfiguration -Path ./CreateViewsWithDifferentVisibility -Wait -Verbose
```

### Example 4: Create Views for npm Feed

```powershell
Configuration CreateNpmFeedViews {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Development view for pre-release npm packages
        AzDoArtifactFeedView 'NpmDevView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNpm'
            ViewName = 'Development'
            ViewType = 'release'
            ViewVisibility = 'private'
            Ensure = 'Present'
        }
        
        # Production view for stable npm packages
        AzDoArtifactFeedView 'NpmProdView' {
            ProjectName = 'MyProject'
            FeedName = 'CompanyNpm'
            ViewName = 'Production'
            ViewType = 'release'
            ViewVisibility = 'collection'
            Ensure = 'Present'
            DependsOn = '[AzDoArtifactFeedView]NpmDevView'
        }
    }
}

CreateNpmFeedViews
Start-DscConfiguration -Path ./CreateNpmFeedViews -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Query and Create

```powershell
# Get current feed views
$properties = @{
    ProjectName = 'MyProject'
    FeedName = 'CompanyNuGet'
    ViewName = 'Release'
}

$result = Invoke-DscResource -Name 'AzDoArtifactFeedView' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, FeedName, ViewName, ViewType, ViewVisibility

# Create a new feed view
$setProperties = @{
    ProjectName = 'MyProject'
    FeedName = 'CompanyNuGet'
    ViewName = 'Release'
    ViewType = 'release'
    ViewVisibility = 'collection'
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoArtifactFeedView' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### View Types

- **Release Views** - Packages must be explicitly promoted to the view; commonly used for production releases
- **Implicit Views** - Automatically includes packages matching view criteria; useful for pre-release or latest builds
- Most workflows use release views for controlled package promotion

### Visibility Levels

- **Private** - Only visible to creator and those with explicit permissions; suitable for experimental packages
- **Collection** - Visible to all projects in the project collection; good for shared projects
- **Organization** - Visible across the entire organization; suitable for company-wide packages
- **AAD Tenant** - Visible to all users in Azure AD tenant; for widely distributed packages

### Package Promotion Workflow

- Views enable a promotion workflow where packages move through stages
- Development -> PreRelease -> Release is a common pattern
- Clients can reference specific views as package sources
- Allows different teams to access different package versions

### Common Use Cases

1. **Release Workflow**: PreRelease view for candidates, Release view for stable
2. **Multi-Environment**: Dev, Test, Staging, Prod views for deployment stages
3. **Package Lifecycle**: Active, Deprecated, Legacy views for version management
4. **Internal Distribution**: Private internal view, public external view

## Troubleshooting

### Issue: "Feed Not Found"

**Cause**: The specified feed does not exist in the project.

**Solution**:
```powershell
# Create the feed first using AzDoArtifactFeed resource
# Verify the feed name is correct and matches case
```

### Issue: "View Name Already Exists"

**Cause**: A view with the same name already exists in the feed.

**Solution**:
```powershell
# Use a unique view name
# Or use Ensure = 'Present' which is idempotent
# Check existing views in the feed settings
```

### Issue: "Cannot Access Package Through View"

**Cause**: Package is not in the view or visibility/permissions restrict access.

**Solution**:
```powershell
# Verify package is promoted to the view if using release view
# Check view visibility allows access for your user/group
# Verify feed permissions allow viewing
```

### Issue: "Cannot Create View - Insufficient Permissions"

**Cause**: Authentication account lacks permission to create views.

**Solution**:
```powershell
# Verify account has feed administrator role
# Check project permissions
# Ensure Personal Access Token has appropriate scopes
```

## Related Resources

- [AzDoArtifactFeed](AzDoArtifactFeed.md) - Create and manage artifact feeds
- [AzDoArtifactFeedPermission](AzDoArtifactFeedPermission.md) - Manage feed permissions
- [AzDoArtifactFeedSettings](AzDoArtifactFeedSettings.md) - Configure feed settings
- [AzDoProject](AzDoProject.md) - Create projects containing feeds

## See Also

- [Azure Artifacts Feed Views](https://docs.microsoft.com/en-us/azure/devops/artifacts/concepts/feeds#views)
- [Azure Artifacts Package Promotion](https://docs.microsoft.com/en-us/azure/devops/artifacts/feeds/views)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
