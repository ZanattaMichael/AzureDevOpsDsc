# AzDoArtifactFeedPermission Resource

## Description

The `AzDoArtifactFeedPermission` DSC resource is used to manage role-based permissions for Azure Artifacts feeds in Azure DevOps. It allows you to control which groups and users can view, publish, edit, or manage artifact feeds, ensuring that package repositories are accessible only to authorized users and teams.

## Syntax

```powershell
AzDoArtifactFeedPermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    FeedName = [String] $FeedName
    [ Permissions = [HashTable[]] $Permissions ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

- **FeedName** [String] - The name of the artifact feed.

### Optional Properties

- **Permissions** [HashTable[]] - An array of permission hashtables, each containing:
  - `Identity` - The group or user identity
  - `Role` - The role name (e.g., 'Reader', 'Collaborator', 'Contributor', 'Owner')
  - `Allow` - Boolean indicating if permission is allowed
  - `Deny` - Boolean indicating if permission is denied

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **FeedName** - The name of the feed
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Feed Access to Team

```powershell
Configuration GrantFeedAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedPermission 'PublicFeedAccess' {
            ProjectName = 'MyProject'
            FeedName    = 'Public Components'
            Permissions = @(
                @{
                    Identity = 'Development Team'
                    Role     = 'Reader'
                },
                @{
                    Identity = 'Build Team'
                    Role     = 'Contributor'
                }
            )
            Ensure      = 'Present'
        }
    }
}

GrantFeedAccess
Start-DscConfiguration -Path ./GrantFeedAccess -Wait -Verbose
```

### Example 2: Restrict Private Feed Access

```powershell
Configuration RestrictPrivateFeed {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedPermission 'PrivateFeed' {
            ProjectName = 'MyProject'
            FeedName    = 'Internal Packages'
            Permissions = @(
                @{
                    Identity = 'Package Owners'
                    Role     = 'Owner'
                },
                @{
                    Identity = 'Core Team'
                    Role     = 'Contributor'
                },
                @{
                    Identity = 'Contractors'
                    Role     = 'Reader'
                }
            )
            Ensure      = 'Present'
        }
    }
}

RestrictPrivateFeed
Start-DscConfiguration -Path ./RestrictPrivateFeed -Wait -Verbose
```

### Example 3: Configure Multiple Feed Permissions

```powershell
Configuration MultiFeedPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedPermission 'PublicComponentsFeed' {
            ProjectName = 'MyProject'
            FeedName    = 'Public Components'
            Permissions = @(
                @{ Identity = 'Everyone'; Role = 'Reader' },
                @{ Identity = 'Development Team'; Role = 'Contributor' }
            )
            Ensure      = 'Present'
        }
        
        AzDoArtifactFeedPermission 'InternalToolsFeed' {
            ProjectName = 'MyProject'
            FeedName    = 'Internal Tools'
            Permissions = @(
                @{ Identity = 'Tool Developers'; Role = 'Owner' },
                @{ Identity = 'Development Team'; Role = 'Reader' }
            )
            Ensure      = 'Present'
        }
        
        AzDoArtifactFeedPermission 'ThirdPartyFeed' {
            ProjectName = 'MyProject'
            FeedName    = 'Third Party Dependencies'
            Permissions = @(
                @{ Identity = 'Package Managers'; Role = 'Owner' },
                @{ Identity = 'Developers'; Role = 'Reader' }
            )
            Ensure      = 'Present'
        }
    }
}

MultiFeedPermissions
Start-DscConfiguration -Path ./MultiFeedPermissions -Wait -Verbose
```

### Example 4: Query Feed Permissions

```powershell
# Get the current state of feed permissions
$properties = @{
    ProjectName = 'MyProject'
    FeedName    = 'Public Components'
}

$result = Invoke-DscResource -Name 'AzDoArtifactFeedPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, FeedName, Permissions
```

### Example 5: Allow Pipeline Access to Feed

```powershell
Configuration AllowPipelineFeedAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeedPermission 'PipelineFeedAccess' {
            ProjectName = 'MyProject'
            FeedName    = 'Build Artifacts'
            Permissions = @(
                @{
                    Identity = 'Build Service'
                    Role     = 'Contributor'
                },
                @{
                    Identity = 'Release Service'
                    Role     = 'Reader'
                }
            )
            Ensure      = 'Present'
        }
    }
}

AllowPipelineFeedAccess
Start-DscConfiguration -Path ./AllowPipelineFeedAccess -Wait -Verbose
```

### Example 6: Create Feed with Permissions

```powershell
Configuration CreateFeedWithPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoArtifactFeed 'CompanyFeed' {
            ProjectName = 'MyProject'
            FeedName    = 'Company Packages'
            FeedType    = 'npm'
            Ensure      = 'Present'
        }
        
        AzDoArtifactFeedPermission 'FeedPermissions' {
            ProjectName = 'MyProject'
            FeedName    = 'Company Packages'
            Permissions = @(
                @{ Identity = 'NPM Team'; Role = 'Owner' },
                @{ Identity = 'Developers'; Role = 'Contributor' },
                @{ Identity = 'QA'; Role = 'Reader' }
            )
            Ensure      = 'Present'
            DependsOn   = '[AzDoArtifactFeed]CompanyFeed'
        }
    }
}

CreateFeedWithPermissions
Start-DscConfiguration -Path ./CreateFeedWithPermissions -Wait -Verbose
```

## Important Notes

### Feed Roles

- **Reader** - Can download and view packages, but cannot publish
- **Collaborator** - Same as Reader, can view and download packages
- **Contributor** - Can publish, download, and view packages
- **Owner** - Full control including feed settings and permissions

### Feed Types

- NuGet feeds for .NET packages
- npm feeds for JavaScript packages
- Python feeds for Python packages
- Maven feeds for Java packages
- Universal packages for any content

### Best Practices

- Use the principle of least privilege for access
- Create separate feeds for different package types
- Restrict publish permissions to authorized teams
- Grant read access broadly for consumption
- Regularly audit feed permissions
- Document feed purposes and access policies

### Permission Management

- Feeds can be project-scoped or organization-scoped
- Organization-scoped feeds can be shared across projects
- Permissions are role-based for simplicity
- Service connections can be granted access to feeds

## Troubleshooting

### Issue: "Feed Not Found"

**Cause**: The artifact feed does not exist

**Solution**:
```powershell
# Create the feed first using AzDoArtifactFeed resource
# Verify feed name matches exactly (case-sensitive)
```

### Issue: "Cannot Set Feed Permissions"

**Cause**: Group does not exist or insufficient permissions

**Solution**:
- Verify the group exists in the project or organization
- Ensure user has feed admin permissions
- Check personal access token has "Packaging (read & write)" scope

### Issue: "Pipelines Cannot Access Feed"

**Cause**: Service account lacks appropriate role

**Solution**:
- Grant "Contributor" role for publishing packages
- Grant "Reader" role for consuming packages
- Verify service connection has access to the feed

## Related Resources

- [AzDoArtifactFeed](AzDoArtifactFeed) - Create and manage artifact feeds
- [AzDoProjectPermission](AzDoProjectPermission) - Manage project-level permissions
- [AzDoGroupPermission](AzDoGroupPermission) - Manage group permissions
- [AzDoPipeline](AzDoPipeline) - Create pipelines that use feeds

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
