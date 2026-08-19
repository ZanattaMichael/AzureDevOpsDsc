# Best Practices Guide

This guide provides best practices and recommendations for using AzureDevOpsDscNative effectively in production environments.

## Table of Contents

1. [Configuration Management](#configuration-management)
2. [Security Best Practices](#security-best-practices)
3. [Performance Optimization](#performance-optimization)
4. [Error Handling & Troubleshooting](#error-handling--troubleshooting)
5. [Large-Scale Deployments](#large-scale-deployments)
6. [Testing & Validation](#testing--validation)
7. [Maintenance & Updates](#maintenance--updates)

## Configuration Management

### 1. Organize Configurations by Environment

Separate configurations for different environments:

```powershell
# Structure example
.
├── Configurations
│   ├── Dev
│   │   ├── BaseConfig.ps1
│   │   └── Services.ps1
│   ├── Staging
│   │   ├── BaseConfig.ps1
│   │   └── Services.ps1
│   └── Production
│       ├── BaseConfig.ps1
│       └── Services.ps1
├── Common
│   └── SharedFunctions.ps1
└── Deploy.ps1
```

### 2. Use Configuration Data Files

Separate data from configuration logic:

```powershell
# ConfigurationData.psd1
@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            Environment = 'Production'
            OrganizationName = 'ProdOrg'
            Projects = @(
                @{ Name = 'Project1'; Template = 'Agile' }
                @{ Name = 'Project2'; Template = 'Scrum' }
            )
        }
    )
}

# Configuration.ps1
Configuration DeployAzureDevOps {
    Param([hashtable]$ConfigurationData)
    
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node $AllNodes.NodeName {
        foreach ($project in $Node.Projects) {
            AzDoProject "Project_$($project.Name)" {
                Ensure              = 'Present'
                ProjectName         = $project.Name
                ProcessTemplate     = $project.Template
                SourceControlType   = 'Git'
                Visibility          = 'Private'
            }
        }
    }
}

# Usage
$data = Import-PowerShellDataFile -Path ConfigurationData.psd1
DeployAzureDevOps -ConfigurationData $data
```

### 3. Implement Idempotency Correctly

Ensure configurations are idempotent (safe to run multiple times):

```powershell
# Good: Idempotent
Configuration IdempotentConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # This will only be applied if project is present
        AzDoProjectGroup 'ProjectAdmins' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            GroupName           = 'Project Admins'
            DependsOn           = '[AzDoProject]MyProject'
        }
    }
}

# Bad: Not idempotent - will fail if run twice
Configuration NonIdempotent {
    Node localhost {
        Script CreateProject {
            SetScript = {
                # Direct API call without idempotence checking
            }
        }
    }
}
```

### 4. Use DependsOn for Resource Ordering

Explicitly define resource dependencies:

```powershell
Configuration WithDependencies {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Create project first
        AzDoProject 'MyProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Create repo only after project exists
        AzDoGitRepository 'MainRepo' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            RepositoryName      = 'MainRepository'
            DependsOn           = '[AzDoProject]MyProject'
        }
        
        # Configure permissions only after repo exists
        AzDoGitPermission 'RepoAccess' {
            RepositoryName      = 'MainRepository'
            ProjectName         = 'MyProject'
            IdentityName        = 'Project Admins'
            PermissionName      = 'Contribute'
            Allow               = $true
            DependsOn           = '[AzDoGitRepository]MainRepo'
        }
    }
}
```

### 5. Version Your Configurations

Use version control for all configurations:

```powershell
# Version configuration files
git tag -a v1.0.0 -m "Initial DSC configuration"

# Document changes
<#
v1.0.0 - Initial Release
  - Basic project setup
  - Team management
  - Repository configuration

v1.1.0 - Added Pipeline Support
  - Pipeline creation
  - Environment management
  - Check configuration
#>
```

## Security Best Practices

### 1. Never Hardcode Credentials

```powershell
# Bad: Credentials in configuration
Configuration BadCredentials {
    Node localhost {
        # NEVER DO THIS
        $token = 'your-pat-token-hardcoded'
    }
}

# Good: Use secure storage
Configuration GoodCredentials {
    Node localhost {
        # Retrieve from secure storage
        $token = Get-Secret -Name 'AzureDevOpsPAT' -AsPlainText
    }
}
```

### 2. Use PsDscRunAsCredential for Sensitive Operations

```powershell
Configuration SecureExecution {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Run with specific credential
        AzDoProject 'MyProject' {
            Ensure                 = 'Present'
            ProjectName            = 'MyProject'
            SourceControlType      = 'Git'
            ProcessTemplate        = 'Agile'
            Visibility             = 'Private'
            PsDscRunAsCredential   = $credential
        }
    }
}
```

### 3. Implement Role-Based Access Control (RBAC)

```powershell
Configuration RBACSetup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Create role-specific groups
        AzDoOrganizationGroup 'Developers' {
            Ensure              = 'Present'
            GroupName           = 'Developers'
            GroupDescription    = 'Development team members'
        }
        
        AzDoOrganizationGroup 'Admins' {
            Ensure              = 'Present'
            GroupName           = 'Admins'
            GroupDescription    = 'Azure DevOps administrators'
        }
        
        # Assign minimal required permissions
        AzDoGroupPermission 'DeveloperPermissions' {
            GroupName           = 'Developers'
            PermissionName      = 'Create Repository'
            Allow               = $true
            DependsOn           = '[AzDoOrganizationGroup]Developers'
        }
        
        AzDoGroupPermission 'AdminPermissions' {
            GroupName           = 'Admins'
            PermissionName      = 'Administer'
            Allow               = $true
            DependsOn           = '[AzDoOrganizationGroup]Admins'
        }
    }
}
```

### 4. Audit and Monitor Configuration Changes

```powershell
# Enable DSC logging
Enable-DscDebug -Force

# Check configuration status
Get-DscConfigurationStatus -All

# Review compliance
Get-DscConfigurationStatus | Where-Object Type -eq 'Consistency'
```

### 5. Implement Least Privilege

```powershell
Configuration LeastPrivilege {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Grant only necessary permissions
        AzDoGitPermission 'ReadOnlyAccess' {
            RepositoryName      = 'MainRepository'
            ProjectName         = 'MyProject'
            IdentityName        = 'Readers'
            PermissionName      = 'GenericRead'
            Allow               = $true
        }
        
        AzDoGitPermission 'ContributorAccess' {
            RepositoryName      = 'MainRepository'
            ProjectName         = 'MyProject'
            IdentityName        = 'Contributors'
            PermissionName      = 'Contribute'
            Allow               = $true
        }
    }
}
```

## Performance Optimization

### 1. Batch Related Resources

Group related resource configurations:

```powershell
Configuration OptimizedBatching {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Create all projects together
        $projects = @('Project1', 'Project2', 'Project3')
        
        foreach ($projectName in $projects) {
            AzDoProject "Project_$projectName" {
                Ensure              = 'Present'
                ProjectName         = $projectName
                SourceControlType   = 'Git'
                ProcessTemplate     = 'Agile'
                Visibility          = 'Private'
            }
        }
    }
}
```

### 2. Use Parallel Processing Where Appropriate

```powershell
# Configure independent resources in parallel
Configuration ParallelConfiguration {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # These can run in parallel (no dependencies)
        AzDoProject 'Project1' {
            Ensure              = 'Present'
            ProjectName         = 'Project1'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        AzDoProject 'Project2' {
            Ensure              = 'Present'
            ProjectName         = 'Project2'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Scrum'
            Visibility          = 'Private'
        }
        
        # These must wait for projects above (have dependencies)
        AzDoGitRepository 'Repo1' {
            Ensure              = 'Present'
            ProjectName         = 'Project1'
            RepositoryName      = 'Repository1'
            DependsOn           = '[AzDoProject]Project1'
        }
    }
}
```

### 3. Monitor Resource Performance

```powershell
# Measure configuration execution time
$startTime = Get-Date
$config | Start-DscConfiguration -Wait -Verbose
$endTime = Get-Date

Write-Host "Configuration took $($endTime - $startTime) to complete"
```

## Error Handling & Troubleshooting

### 1. Implement Error Handling

```powershell
Configuration WithErrorHandling {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
            ErrorAction         = 'Stop'
        }
    }
}

# Execute with error handling
try {
    $config | Start-DscConfiguration -Wait -Verbose -ErrorAction Stop
}
catch {
    Write-Error "DSC configuration failed: $_"
    # Implement recovery logic
}
```

### 2. Enable Verbose Logging

```powershell
# Enable verbose output for troubleshooting
$config | Start-DscConfiguration -Wait -Verbose

# Check DSC event log
Get-WinEvent -LogName 'DSC/Operational' | Select-Object TimeCreated, Message | Out-GridView
```

### 3. Test Before Deploying

```powershell
Configuration TestConfiguration {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Your configuration here
    }
}

# Test without applying changes
Test-DscConfiguration -Path ./TestConfiguration -Verbose

# Check what would change
Compare-DscConfiguration -ReferenceConfiguration ./TestConfiguration
```

## Large-Scale Deployments

For large-scale deployments across many projects and teams, the recommended approach is to use the
companion **[AZDO-DSC-LCM](https://github.com/ZanattaMichael/AzDO-DSC-LCM)** (Local Configuration
Manager). It provides a pipeline-based LCM built on [Datum](https://github.com/gaelcolas/Datum)
that enables layered YAML configuration merging, dependency ordering, conditional logic, and
organisation-wide policy enforcement without writing individual DSC configuration scripts per project.

See the [LCM Configuration](LCMConfiguration) wiki page for a full walkthrough and example
directory layout. Example configurations are available in the
[AZDO-DSC-LCM repository](https://github.com/ZanattaMichael/AzDO-DSC-LCM/tree/main/Example%20Configuration).

### Basic LCM Invocation

```powershell
$params = @{
    AzureDevopsOrganizationName = 'my-organization'
    ConfigurationDirectory      = 'C:\Datum\DSCOutput\'
    ConfigurationUrl            = 'https://my-config-repo/path'
    AuthenticationType          = 'ManagedIdentity'
    Mode                        = 'Set'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```

### Example Resource Stub (YAML)

Resource configuration stubs are written in YAML and merged by Datum. Organisation-wide policy sits
at the top of the merge precedence; per-project files override it.

```yaml
resources:
  - name: Project
    type: AzureDevOpsDscNative/AzDoProject
    properties:
      projectName: $ProjectName
      projectDescription: $ProjectDescription
      visibility: private
      SourceControlType: Git
      ProcessTemplate: Agile
```

### When to Use the LCM vs Direct DSC

| Scenario | Use |
|----------|-----|
| Single project, small team | Direct `Invoke-DscResource` or DSC configuration script |
| Multiple projects, shared policy | **AZDO-DSC-LCM** (recommended) |
| CI/CD pipeline at org scale | **AZDO-DSC-LCM** with Managed Identity or Workload Identity |
| One-off or exploratory changes | Direct `Invoke-DscResource` |

## Testing & Validation

### 1. Unit Testing DSC Resources

```powershell
# Create Pester tests for configurations
Describe 'Azure DevOps DSC Configuration' {
    It 'Should create project' {
        # Mock the Azure DevOps API
        Mock Get-DscResource { return $true }
        
        # Test your configuration
        { MyConfiguration | Start-DscConfiguration -Wait } | Should -Not -Throw
    }
}

# Run tests
Invoke-Pester -Path .\ConfigurationTests.psd1 -Verbose
```

### 2. Integration Testing

```powershell
# Test against actual Azure DevOps instance
Describe 'Azure DevOps Integration' {
    It 'Should create and verify project' {
        $config | Start-DscConfiguration -Wait
        
        # Verify the resource was created
        Get-AzDoProject -ProjectName 'TestProject' | Should -Not -BeNullOrEmpty
    }
    
    AfterAll {
        # Clean up test resources
        Remove-AzDoProject -ProjectName 'TestProject'
    }
}
```

## Maintenance & Updates

### 1. Update Module Regularly

```powershell
# Check for module updates
Find-Module AzureDevOpsDscNative | Select-Object Name, Version

# Update to latest version
Update-Module -Name AzureDevOpsDscNative

# Verify update
Get-Module AzureDevOpsDscNative -ListAvailable | Sort-Object Version
```

### 2. Document Configuration Changes

```powershell
# Keep detailed changelog
<#
CHANGELOG.md

## [2.0.0] - 2025-01-15
### Added
- Support for new pipeline features
- Environment permissions management

### Changed
- Updated authentication module
- Improved error messages

### Deprecated
- Legacy authentication method

### Fixed
- Bug in permission assignment
- Resource naming issue
#>
```

### 3. Implement Configuration Drift Monitoring

```powershell
# Check for configuration drift
Get-DscConfigurationStatus

# Monitor compliance over time
$status = Get-DscConfigurationStatus
if ($status.ResourcesNotInDesiredState.Count -gt 0) {
    Write-Warning "Configuration drift detected"
    # Take corrective action
    Start-DscConfiguration -Path ./Configuration -Wait
}
```

### 4. Backup Configurations

```powershell
# Regular backups of configurations
$backupPath = "C:\Backups\DSC\$(Get-Date -Format 'yyyyMMdd')"
Copy-Item -Path 'C:\DSC\Configurations' -Destination $backupPath -Recurse

# Version control
git commit -m "Configuration backup $(Get-Date -Format 'yyyy-MM-dd')"
```

## Summary Checklist

**Configuration Management**
- [ ] Organize configurations by environment
- [ ] Use configuration data files
- [ ] Implement idempotency
- [ ] Define dependencies explicitly
- [ ] Version configurations

**Security**
- [ ] Never hardcode credentials
- [ ] Use secure credential storage
- [ ] Implement RBAC
- [ ] Audit changes
- [ ] Apply least privilege

**Performance**
- [ ] Batch related resources
- [ ] Use parallel processing
- [ ] Monitor performance

**Reliability**
- [ ] Handle errors properly
- [ ] Enable logging
- [ ] Test before deployment
- [ ] Progressive rollout
- [ ] Monitor drift

**Maintenance**
- [ ] Keep module updated
- [ ] Document changes
- [ ] Monitor compliance
- [ ] Regular backups
