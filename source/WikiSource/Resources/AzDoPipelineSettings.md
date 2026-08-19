# AzDoPipelineSettings Resource

## Description

The `AzDoPipelineSettings` DSC resource is used to manage project-level pipeline security and configuration settings in Azure DevOps. These settings, found in Project Settings > Pipelines > Settings, control security policies, badge access, and CI/CD behavior across all pipelines in a project. This resource allows you to configure and enforce organizational security policies for pipeline execution and access controls.

## Syntax

```powershell
AzDoPipelineSettings [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    [ EnforceJobAuthScope = [String] {'', 'true', 'false'} ]
    [ EnforceJobAuthScopeForReleases = [String] {'', 'true', 'false'} ]
    [ EnforceReferencedRepoScopedToken = [String] {'', 'true', 'false'} ]
    [ EnforceSettableVar = [String] {'', 'true', 'false'} ]
    [ PublishPipelineMetadata = [String] {'', 'true', 'false'} ]
    [ StatusBadgesArePrivate = [String] {'', 'true', 'false'} ]
    [ DisableClassicPipelineCreation = [String] {'', 'true', 'false'} ]
    [ DisableImpliedYAMLCiTrigger = [String] {'', 'true', 'false'} ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project. This is the unique identifier for the project whose pipeline settings will be managed.

### Optional Properties

All settings use a tri-state string value: empty string `''` (default, not managed), `'true'` (enabled), or `'false'` (disabled). This allows the resource to manage only specified settings while leaving others untouched.

- **EnforceJobAuthScope** [String] - Limit job authorization scope to the current project for non-release pipelines:
  - `''` - Not managed by this resource
  - `'true'` - Restrict job token to project scope
  - `'false'` - Allow job token to access organization resources

- **EnforceJobAuthScopeForReleases** [String] - Limit job authorization scope to the current project for release pipelines:
  - `''` - Not managed by this resource
  - `'true'` - Restrict release job token to project scope
  - `'false'` - Allow release job token to access organization resources

- **EnforceReferencedRepoScopedToken** [String] - Protect access to repositories in YAML pipelines by requiring scoped tokens:
  - `''` - Not managed by this resource
  - `'true'` - Require scoped tokens for repo access
  - `'false'` - Allow broader token access

- **EnforceSettableVar** [String] - Limit variables that can be set at queue time (prevents pipeline variables from being overridden):
  - `''` - Not managed by this resource
  - `'true'` - Restrict settable variables at queue time
  - `'false'` - Allow all variables to be overridden at queue time

- **PublishPipelineMetadata** [String] - Publish pipeline metadata to enable integration scenarios:
  - `''` - Not managed by this resource
  - `'true'` - Enable metadata publishing
  - `'false'` - Disable metadata publishing

- **StatusBadgesArePrivate** [String] - Disable anonymous access to pipeline status badges:
  - `''` - Not managed by this resource
  - `'true'` - Make status badges private (authentication required)
  - `'false'` - Allow anonymous badge access

- **DisableClassicPipelineCreation** [String] - Disable creation of classic (non-YAML) build and release pipelines:
  - `''` - Not managed by this resource
  - `'true'` - Prevent new classic pipeline creation
  - `'false'` - Allow classic pipeline creation

- **DisableImpliedYAMLCiTrigger** [String] - Disable implied CI triggers on YAML pipelines:
  - `''` - Not managed by this resource
  - `'true'` - Require explicit CI trigger configuration
  - `'false'` - Enable implicit CI triggers by default

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Settings should be configured
  - `'Absent'` - No-op for this resource (settings cannot be removed)

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **EnforceJobAuthScope** - Current value of the job auth scope setting
- **EnforceJobAuthScopeForReleases** - Current value of the release job auth scope setting
- **EnforceReferencedRepoScopedToken** - Current value of the repo scoped token setting
- **EnforceSettableVar** - Current value of the settable variable setting
- **PublishPipelineMetadata** - Current value of the metadata publishing setting
- **StatusBadgesArePrivate** - Current value of the badge privacy setting
- **DisableClassicPipelineCreation** - Current value of the classic pipeline creation setting
- **DisableImpliedYAMLCiTrigger** - Current value of the implied CI trigger setting
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Enable Security Hardening for Pipelines

```powershell
Configuration HardenPipelineSettings {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelineSettings 'HardenedPipelines' {
            ProjectName = 'MyProject'
            EnforceJobAuthScope = 'true'
            EnforceJobAuthScopeForReleases = 'true'
            EnforceReferencedRepoScopedToken = 'true'
            StatusBadgesArePrivate = 'true'
            DisableClassicPipelineCreation = 'true'
            Ensure = 'Present'
        }
    }
}

HardenPipelineSettings
Start-DscConfiguration -Path ./HardenPipelineSettings -Wait -Verbose
```

### Example 2: Configure Selective Pipeline Security Settings

```powershell
Configuration SelectiveSecuritySettings {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelineSettings 'ProjectSecurityPolicy' {
            ProjectName = 'MyProject'
            # Enforce job auth scope for regular pipelines
            EnforceJobAuthScope = 'true'
            # Do NOT change release pipeline auth scope setting
            EnforceJobAuthScopeForReleases = ''
            # Protect repository access
            EnforceReferencedRepoScopedToken = 'true'
            # Allow variable override at queue time
            EnforceSettableVar = 'false'
            # Enable metadata for integrations
            PublishPipelineMetadata = 'true'
            # Don't manage badge privacy setting
            StatusBadgesArePrivate = ''
            # Require YAML pipelines for new builds
            DisableClassicPipelineCreation = 'true'
            # Don't manage CI trigger setting
            DisableImpliedYAMLCiTrigger = ''
            Ensure = 'Present'
        }
    }
}

SelectiveSecuritySettings
Start-DscConfiguration -Path ./SelectiveSecuritySettings -Wait -Verbose
```

### Example 3: Enforce Strict Security Policies

```powershell
Configuration StrictSecurityPolicies {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelineSettings 'StrictSecurity' {
            ProjectName = 'MyProject'
            EnforceJobAuthScope = 'true'
            EnforceJobAuthScopeForReleases = 'true'
            EnforceReferencedRepoScopedToken = 'true'
            EnforceSettableVar = 'true'
            PublishPipelineMetadata = 'false'
            StatusBadgesArePrivate = 'true'
            DisableClassicPipelineCreation = 'true'
            DisableImpliedYAMLCiTrigger = 'true'
            Ensure = 'Present'
        }
    }
}

StrictSecurityPolicies
Start-DscConfiguration -Path ./StrictSecurityPolicies -Wait -Verbose
```

### Example 4: Permissive Settings for Development Project

```powershell
Configuration PermissiveDevSettings {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelineSettings 'DevelopmentPipelines' {
            ProjectName = 'Development'
            # Allow broader scope access
            EnforceJobAuthScope = 'false'
            EnforceJobAuthScopeForReleases = 'false'
            # Allow variable override for debugging
            EnforceSettableVar = 'false'
            # Enable classic pipelines for flexibility
            DisableClassicPipelineCreation = 'false'
            # Don't enforce strict CI trigger configuration
            DisableImpliedYAMLCiTrigger = 'false'
            # Don't manage other settings
            EnforceReferencedRepoScopedToken = ''
            PublishPipelineMetadata = ''
            StatusBadgesArePrivate = ''
            Ensure = 'Present'
        }
    }
}

PermissiveDevSettings
Start-DscConfiguration -Path ./PermissiveDevSettings -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Query and Update Settings

```powershell
# Get current pipeline settings
$properties = @{
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoPipelineSettings' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, EnforceJobAuthScope, EnforceReferencedRepoScopedToken, `
    StatusBadgesArePrivate, DisableClassicPipelineCreation

# Update specific pipeline settings
$setProperties = @{
    ProjectName = 'MyProject'
    EnforceJobAuthScope = 'true'
    EnforceReferencedRepoScopedToken = 'true'
    StatusBadgesArePrivate = 'true'
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoPipelineSettings' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Tri-State Design

- Empty string `''` means "don't manage this setting" - the current value is preserved
- `'true'` and `'false'` are strings (not boolean) to support the "unmanaged" state
- Only explicitly set settings are reconciled; others remain unchanged
- This prevents accidentally disabling security policies when only updating one setting

### Job Authorization Scope

- **EnforceJobAuthScope** controls token scope for standard build pipelines
- **EnforceJobAuthScopeForReleases** controls token scope for release pipelines
- Restricting to project scope prevents pipelines from accessing organization-level resources
- Recommended for most organizations for security hardening

### Repository Access Protection

- **EnforceReferencedRepoScopedToken** requires scoped tokens for repo access in YAML
- Provides fine-grained access control for repository operations
- Recommended for organizations with strict security requirements
- Works with multi-repo pipelines

### Variable and Configuration Controls

- **EnforceSettableVar** prevents variables from being overridden at pipeline queue time
- Useful for controlling production deployments and sensitive configurations
- Can be too restrictive for development environments
- Useful for protecting build/release parameters

### Badge and Metadata

- **StatusBadgesArePrivate** controls who can view pipeline status badges (read-only)
- **PublishPipelineMetadata** enables integration scenarios and external tools
- Badge URLs contain sensitive project information; making private is recommended
- Metadata publishing enables audit scenarios and external integrations

### Pipeline Type Controls

- **DisableClassicPipelineCreation** forces use of YAML pipelines for new pipelines
- Recommended for organizations standardizing on YAML/infrastructure-as-code
- Existing classic pipelines continue to run; this only prevents new ones
- Useful for enforcing consistent pipeline management practices

## Troubleshooting

### Issue: "Only Specified Settings Are Updated"

**Behavior**: Some settings not specified in configuration remain unchanged.

**Explanation**: This is intentional. Empty string means "don't manage this setting." This design prevents accidentally overriding unmanaged settings.

**Solution**:
```powershell
# Explicitly set all settings you want to manage
# Leave unmanaged settings as empty string ''
# Or query current settings with Get method first
```

### Issue: "Changes Are Not Reflected Immediately"

**Cause**: Pipelines cache settings or browser caching.

**Solution**:
```powershell
# Refresh the browser after making changes
# Restart pipeline agents if they cache settings
# Run a new pipeline build to test new settings
# Check Azure Pipelines documentation for setting propagation time
```

### Issue: "Cannot Disable Job Authorization Scope"

**Cause**: Trying to set to a value not allowed by organization policy.

**Solution**:
```powershell
# Check organization-level policy overrides
# Organization-level settings may enforce stricter rules
# Contact organization administrator if policy blocks change
```

## Related Resources

- [AzDoPipeline](AzDoPipeline) - Create and manage YAML pipelines
- [AzDoProject](AzDoProject) - Create and manage projects
- [AzDoPipelineEnvironment](AzDoPipelineEnvironment) - Create deployment environments
- [AzDoServiceConnection](AzDoServiceConnection) - Create service connections for pipelines

## See Also

- [Azure Pipelines Security Settings](https://docs.microsoft.com/en-us/azure/devops/pipelines/policies/settings)
- [Azure Pipelines Security Best Practices](https://docs.microsoft.com/en-us/azure/devops/pipelines/security/overview)
- [Azure Pipelines Job Authorization Scope](https://docs.microsoft.com/en-us/azure/devops/pipelines/security/scope)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
