# AzDoPipelinePermission Resource

## Description

The `AzDoPipelinePermission` DSC resource is used to manage role-based permissions for individual pipelines (build and release) in Azure DevOps. It allows you to grant or restrict access to specific pipelines for groups and users, controlling who can view, edit, execute, or manage each pipeline.

## Syntax

```powershell
AzDoPipelinePermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    PipelineName = [String] $PipelineName
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

- **PipelineName** [String] - The name of the pipeline (build or release).

- **GroupName** [String] - The name of the group whose permissions are being managed.

### Optional Properties

- **isInherited** [Boolean] - Whether permissions are inherited from the project level. Default is `$true`.

- **Permissions** [HashTable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[ProjectName]\GroupName'` (conventionally matching `GroupName` above)
  - `Permission` - A hashtable mapping Build security-namespace bit names to `'Allow'` or `'Deny'`, e.g. `@{ ViewBuilds = 'Allow'; QueueBuilds = 'Allow' }`

  See [Permissions & ACLs](../Permissions.md#azdopipelinepermission) for the full list of valid bit names.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **PipelineName** - The name of the pipeline
- **GroupName** - The name of the group
- **isInherited** - Whether permissions are inherited
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Pipeline Access to Development Team

```powershell
Configuration GrantPipelineAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelinePermission 'CIPipelineAccess' {
            ProjectName  = 'MyProject'
            PipelineName = 'CI-Build'
            GroupName    = '[MyProject]\Development Team'
            isInherited  = $false
            Permissions  = @(
                @{
                    Identity   = '[MyProject]\Development Team'
                    Permission = @{
                        ViewBuilds          = 'Allow'
                        QueueBuilds         = 'Allow'
                        ViewBuildDefinition = 'Allow'
                        EditBuildDefinition = 'Deny'
                    }
                }
            )
            Ensure = 'Present'
        }
    }
}

GrantPipelineAccess
Start-DscConfiguration -Path ./GrantPipelineAccess -Wait -Verbose
```

### Example 2: Configure Multiple Pipeline Permissions

```powershell
Configuration MultiPipelinePermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelinePermission 'CIPipelinePermission' {
            ProjectName  = 'MyProject'
            PipelineName = 'CI-Build'
            GroupName    = '[MyProject]\Developers'
            isInherited  = $false
            Permissions  = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{
                        ViewBuilds          = 'Allow'
                        QueueBuilds         = 'Allow'
                        ViewBuildDefinition = 'Allow'
                    }
                }
            )
            Ensure = 'Present'
        }
        
        AzDoPipelinePermission 'CDPipelinePermission' {
            ProjectName  = 'MyProject'
            PipelineName = 'CD-Release'
            GroupName    = '[MyProject]\DevOps Team'
            isInherited  = $false
            Permissions  = @(
                @{
                    Identity   = '[MyProject]\DevOps Team'
                    Permission = @{
                        ViewBuilds          = 'Allow'
                        QueueBuilds         = 'Allow'
                        ViewBuildDefinition = 'Allow'
                        EditBuildDefinition = 'Allow'
                    }
                }
            )
            Ensure = 'Present'
        }
    }
}

MultiPipelinePermissions
Start-DscConfiguration -Path ./MultiPipelinePermissions -Wait -Verbose
```

### Example 3: Restrict Pipeline to Admins Only

```powershell
Configuration RestrictCriticalPipeline {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelinePermission 'ProductionReleaseAdmins' {
            ProjectName  = 'MyProject'
            PipelineName = 'Production-Release'
            GroupName    = '[MyProject]\Project Admins'
            isInherited  = $false
            Permissions  = @(
                @{
                    Identity   = '[MyProject]\Project Admins'
                    Permission = @{
                        ViewBuilds            = 'Allow'
                        QueueBuilds           = 'Allow'
                        ViewBuildDefinition   = 'Allow'
                        EditBuildDefinition   = 'Allow'
                        DeleteBuildDefinition = 'Allow'
                        AdministerBuildPermissions = 'Allow'
                    }
                }
            )
            Ensure = 'Present'
        }
        
        AzDoPipelinePermission 'ProductionReleaseRestrictDevelopers' {
            ProjectName  = 'MyProject'
            PipelineName = 'Production-Release'
            GroupName    = '[MyProject]\Developers'
            isInherited  = $false
            Permissions  = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{
                        ViewBuilds          = 'Allow'
                        QueueBuilds         = 'Deny'
                        EditBuildDefinition = 'Deny'
                    }
                }
            )
            Ensure = 'Present'
        }
    }
}

RestrictCriticalPipeline
Start-DscConfiguration -Path ./RestrictCriticalPipeline -Wait -Verbose
```

### Example 4: Query Pipeline Permissions

```powershell
# Get the current state of pipeline permissions
$properties = @{
    ProjectName = 'MyProject'
    PipelineName = 'CI-Build'
    GroupName = 'Development Team'
}

$result = Invoke-DscResource -Name 'AzDoPipelinePermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, PipelineName, GroupName, isInherited, Permissions
```

### Example 5: Disable Permission Inheritance

```powershell
Configuration DisableInheritance {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelinePermission 'CustomPipelinePermission' {
            ProjectName  = 'MyProject'
            PipelineName = 'SpecialPipeline'
            GroupName    = '[MyProject]\Special Team'
            isInherited  = $false
            Permissions  = @(
                @{
                    Identity   = '[MyProject]\Special Team'
                    Permission = @{
                        ViewBuilds          = 'Allow'
                        QueueBuilds         = 'Allow'
                        ViewBuildDefinition = 'Allow'
                    }
                }
            )
            Ensure = 'Present'
        }
    }
}

DisableInheritance
Start-DscConfiguration -Path ./DisableInheritance -Wait -Verbose
```

## Important Notes

### Permission Bit Names

The Build security namespace exposes these bit names (see [Permissions & ACLs](../Permissions.md#azdopipelinepermission) for the full table):

- **ViewBuilds** — View builds
- **QueueBuilds** — Queue builds (trigger a run)
- **StopBuilds** — Stop builds
- **ViewBuildDefinition** — View build pipeline
- **EditBuildDefinition** — Edit build pipeline
- **DeleteBuildDefinition** — Delete build pipeline
- **DeleteBuilds** — Delete build records
- **RetainIndefinitely** — Retain build indefinitely
- **ManageBuildQueue** — Manage build queue
- **AdministerBuildPermissions** — Administer build permissions (grant sparingly)

### Inheritance

- When `isInherited` is `$true`, permissions flow from project-level settings
- Setting `isInherited` to `$false` allows custom pipeline-specific permissions
- Inherited permissions can be overridden with explicit denies

### Best Practices

- Use inherited permissions when possible for consistency
- Create separate pipelines for production deployments
- Restrict execution permissions for sensitive pipelines
- Document pipeline access policies

### Pipeline Access Control

- Control both who can execute and who can edit pipelines
- Separate development, testing, and production pipeline access
- Use group-based permissions rather than individual permissions

## Troubleshooting

### Issue: "Pipeline Not Found"

**Cause**: The specified pipeline does not exist

**Solution**:
```powershell
# Verify pipeline name matches exactly (case-sensitive)
# Create the pipeline first using AzDoPipeline resource
# Check project name is correct
```

### Issue: "Cannot Set Pipeline Permissions"

**Cause**: Group does not exist or insufficient permissions

**Solution**:
- Verify the group exists in the project
- Ensure user has pipeline admin permissions
- Check personal access token has sufficient scope

### Issue: "Permission Changes Not Applied"

**Cause**: Inheritance or permission conflicts

**Solution**:
- Set isInherited to $false to override parent permissions
- Check for conflicting Allow/Deny rules
- Explicitly grant/deny required permissions

## Related Resources

- [AzDoPipeline](AzDoPipeline.md) - Create and manage pipelines
- [AzDoProjectPermission](AzDoProjectPermission.md) - Manage project-level permissions
- [AzDoGroupPermission](AzDoGroupPermission.md) - Manage group permissions
- [AzDoProject](AzDoProject.md) - Manage Azure DevOps projects

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
