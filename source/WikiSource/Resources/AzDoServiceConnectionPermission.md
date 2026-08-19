# AzDoServiceConnectionPermission Resource

## Description

The `AzDoServiceConnectionPermission` DSC resource is used to manage role-based permissions for service connections (service endpoints) in Azure DevOps. It allows you to control which groups and users can use, edit, or manage service connections for authentication with external services and platforms.

## Syntax

```powershell
AzDoServiceConnectionPermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    ConnectionName = [String] $ConnectionName
    GroupName = [String] $GroupName
    [ isInherited = [Boolean] $isInherited ]
    [ Permissions = [HashTable[]] $Permissions ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

- **ConnectionName** [String] - The name of the service connection.

- **GroupName** [String] - The name of the group whose permissions are being managed.

### Optional Properties

- **isInherited** [Boolean] - Whether permissions are inherited from the project level. Default is `$true`.

- **Permissions** [HashTable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[ProjectName]\GroupName'` (conventionally matching `GroupName` above)
  - `Permission` - A hashtable mapping Service Endpoint security-namespace bit names to `'Allow'` or `'Deny'`, e.g. `@{ Use = 'Allow'; ViewEndpoint = 'Allow' }`

  See [Permissions & ACLs](../Permissions.md#azdoserviceconnectionpermission) for the full list of valid bit names (`Use`, `Administer`, `Create`, `ViewAuthorization`, `ViewEndpoint`).

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **ConnectionName** - The name of the service connection
- **GroupName** - The name of the group
- **isInherited** - Whether permissions are inherited
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Service Connection Access

```powershell
Configuration GrantServiceConnectionAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoServiceConnectionPermission 'AzureDevAccess' {
            ProjectName    = 'MyProject'
            ConnectionName = 'Azure Dev Subscription'
            GroupName      = '[MyProject]\Development Team'
            isInherited    = $false
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Development Team'
                    Permission = @{ Use = 'Allow'; ViewEndpoint = 'Allow' }
                }
            )
            Ensure         = 'Present'
        }
    }
}

GrantServiceConnectionAccess
Start-DscConfiguration -Path ./GrantServiceConnectionAccess -Wait -Verbose
```

### Example 2: Restrict Production Service Connection

```powershell
Configuration RestrictProductionConnection {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoServiceConnectionPermission 'ProdAccess' {
            ProjectName    = 'MyProject'
            ConnectionName = 'Azure Production Subscription'
            GroupName      = '[MyProject]\DevOps Team'
            isInherited    = $false
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\DevOps Team'
                    Permission = @{ Use = 'Allow'; ViewEndpoint = 'Allow'; Administer = 'Allow' }
                }
            )
            Ensure         = 'Present'
        }
        
        AzDoServiceConnectionPermission 'DeveloperRestriction' {
            ProjectName    = 'MyProject'
            ConnectionName = 'Azure Production Subscription'
            GroupName      = '[MyProject]\Developers'
            isInherited    = $false
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ Use = 'Deny' }
                }
            )
            Ensure         = 'Present'
        }
    }
}

RestrictProductionConnection
Start-DscConfiguration -Path ./RestrictProductionConnection -Wait -Verbose
```

### Example 3: Configure Multiple Service Connection Permissions

```powershell
Configuration MultiServiceConnections {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoServiceConnectionPermission 'DevAzure' {
            ProjectName    = 'MyProject'
            ConnectionName = 'Azure Dev'
            GroupName      = '[MyProject]\Developers'
            isInherited    = $false
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ Use = 'Allow'; ViewEndpoint = 'Allow' }
                }
            )
            Ensure         = 'Present'
        }
        
        AzDoServiceConnectionPermission 'AWS' {
            ProjectName    = 'MyProject'
            ConnectionName = 'AWS Deployment'
            GroupName      = '[MyProject]\DevOps Team'
            isInherited    = $false
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\DevOps Team'
                    Permission = @{ Use = 'Allow'; ViewEndpoint = 'Allow'; Administer = 'Allow' }
                }
            )
            Ensure         = 'Present'
        }
        
        AzDoServiceConnectionPermission 'DockerHub' {
            ProjectName    = 'MyProject'
            ConnectionName = 'Docker Hub Registry'
            GroupName      = '[MyProject]\Developers'
            isInherited    = $false
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ Use = 'Allow'; ViewEndpoint = 'Allow' }
                }
            )
            Ensure         = 'Present'
        }
    }
}

MultiServiceConnections
Start-DscConfiguration -Path ./MultiServiceConnections -Wait -Verbose
```

### Example 4: Query Service Connection Permissions

```powershell
# Get the current state of service connection permissions
$properties = @{
    ProjectName    = 'MyProject'
    ConnectionName = 'Azure Dev Subscription'
    GroupName      = 'Development Team'
}

$result = Invoke-DscResource -Name 'AzDoServiceConnectionPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, ConnectionName, GroupName, isInherited, Permissions
```

### Example 5: Allow Pipeline Access to Service Connection

```powershell
Configuration AllowPipelineServiceAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoServiceConnectionPermission 'PipelineAzureAccess' {
            ProjectName    = 'MyProject'
            ConnectionName = 'Azure Dev Subscription'
            GroupName      = '[MyProject]\Pipeline Service'
            isInherited    = $false
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Pipeline Service'
                    Permission = @{ Use = 'Allow'; ViewEndpoint = 'Allow' }
                }
            )
            Ensure         = 'Present'
        }
    }
}

AllowPipelineServiceAccess
Start-DscConfiguration -Path ./AllowPipelineServiceAccess -Wait -Verbose
```

## Important Notes

### Permission Bit Names

The Service Endpoint security namespace exposes these bit names (see [Permissions & ACLs](../Permissions.md#azdoserviceconnectionpermission) for the full table):

- **Use** — Use the service connection in pipelines
- **Administer** — Administer service connection permissions (not recommended for broad groups)
- **Create** — Create service connections
- **ViewAuthorization** — View service connection authorization settings
- **ViewEndpoint** — View service connection details

### Service Connection Types

- Azure subscriptions, AWS, Docker registries, GitHub, npm feeds, etc.
- Different connection types may have different permission models
- Security should be a priority for cloud connection permissions

### Best Practices

- Use the principle of least privilege for permissions
- Restrict edit permissions to connection owners only
- Create separate connections for dev, staging, and production
- Regularly audit who has access to critical connections
- Document which pipelines use each connection

### Inheritance

- When `isInherited` is `$true`, permissions flow from project settings
- Setting `isInherited` to `$false` allows custom permissions
- Important for restricting production connections

## Troubleshooting

### Issue: "Service Connection Not Found"

**Cause**: The service connection does not exist

**Solution**:
```powershell
# Create the service connection first using AzDoServiceConnection resource
# Verify connection name matches exactly (case-sensitive)
```

### Issue: "Cannot Set Permissions"

**Cause**: Group does not exist or insufficient permissions

**Solution**:
- Verify the group exists in the project
- Ensure user has service connection admin permissions
- Check personal access token has correct scope

### Issue: "Pipelines Cannot Use Connection"

**Cause**: Pipelines lack "Use" permission

**Solution**:
- Grant "Use" permission to pipeline service accounts
- Verify pipelines have access to the connection
- Check project pipeline service connection permissions

## Related Resources

- [AzDoServiceConnection](AzDoServiceConnection) - Create and manage service connections
- [AzDoProjectPermission](AzDoProjectPermission) - Manage project-level permissions
- [AzDoGroupPermission](AzDoGroupPermission) - Manage group permissions
- [AzDoPipeline](AzDoPipeline) - Create pipelines that use service connections

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
