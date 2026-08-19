# AzDoOrganizationGroup Resource

## Description

The `AzDoOrganizationGroup` DSC resource is used to create and manage groups at the organization level in Azure DevOps. These groups can be used for managing permissions and organizing users at the organizational scope.

## Syntax

```powershell
AzDoOrganizationGroup [string] #ResourceName
{
    GroupName = [String] $GroupName
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ GroupDescription = [String] $GroupDescription ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **GroupName** [String] - The name of the organization group. This uniquely identifies the group within the organization.

### Optional Properties

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Group should exist
  - `'Absent'` - Group should be removed

- **GroupDescription** [String] - A description for the organization group that explains its purpose.

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **GroupName** - The name of the group
- **Ensure** - Current state ('Present' or 'Absent')
- **GroupDescription** - The description of the group
- **GroupId** - The unique identifier of the group

## Examples

### Example 1: Create an Organization Group

```powershell
Configuration CreateOrgGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoOrganizationGroup 'DevelopersGroup' {
            Ensure              = 'Present'
            GroupName           = 'Developers'
            GroupDescription    = 'All developers in the organization'
        }
    }
}

CreateOrgGroup
Start-DscConfiguration -Path ./CreateOrgGroup -Wait -Verbose
```

### Example 2: Create Multiple Organization Groups

```powershell
Configuration CreateMultipleOrgGroups {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoOrganizationGroup 'AdminsGroup' {
            Ensure              = 'Present'
            GroupName           = 'Administrators'
            GroupDescription    = 'Organization administrators with full access'
        }
        
        AzDoOrganizationGroup 'ReadersGroup' {
            Ensure              = 'Present'
            GroupName           = 'Readers'
            GroupDescription    = 'Users with read-only access'
        }
        
        AzDoOrganizationGroup 'ContributorsGroup' {
            Ensure              = 'Present'
            GroupName           = 'Contributors'
            GroupDescription    = 'Users who can contribute to projects'
        }
    }
}

CreateMultipleOrgGroups
Start-DscConfiguration -Path ./CreateMultipleOrgGroups -Wait -Verbose
```

### Example 3: Remove an Organization Group

```powershell
Configuration RemoveOrgGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoOrganizationGroup 'RemoveOldGroup' {
            Ensure      = 'Absent'
            GroupName   = 'OldTeam'
        }
    }
}

RemoveOrgGroup
Start-DscConfiguration -Path ./RemoveOrgGroup -Wait -Verbose
```

### Example 4: Using Invoke-DscResource

```powershell
# Get the current state
$properties = @{
    GroupName = 'Developers'
}

$result = Invoke-DscResource -Name 'AzDoOrganizationGroup' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

Write-Host "Group: $($result.GroupName)"
Write-Host "Description: $($result.GroupDescription)"
```

## Important Notes

### Organization-Level Groups

- Organization groups are created at the organizational level
- They can be used across all projects within the organization
- Members can be added using `AzDoGroupMember`
- Permissions can be assigned using `AzDoGroupPermission`

### Group Naming

- Group names must be unique within the organization
- Names are case-insensitive for identification
- Use descriptive names that reflect the group's purpose

### Built-in Groups

Some organizations may have built-in groups that cannot be deleted:
- Project Collection Administrators
- Project Collection Valid Users
- Project Collection Test Service Accounts

## Troubleshooting

### Issue: "Group Already Exists"

**Cause**: A group with the same name already exists

**Solution**:
- Use a unique group name
- Or remove the existing group first

### Issue: "Cannot Create Group Due to Permissions"

**Cause**: Authentication account lacks permissions

**Solution**:
- Verify user is in Project Collection Administrators
- Check Personal Access Token has appropriate scope

## Related Resources

- [AzDoGroupMember](AzDoGroupMember.md) - Add members to organization groups
- [AzDoGroupPermission](AzDoGroupPermission.md) - Manage group permissions
- [AzDoProjectGroup](AzDoProjectGroup.md) - Create project-level groups
- [AzDoUserEntitlement](AzDoUserEntitlement.md) - Manage user entitlements

## See Also

- [Azure DevOps Groups Documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/security/about-security-identity)
- [AzureDevOpsDscNative Home](../Home.md)
