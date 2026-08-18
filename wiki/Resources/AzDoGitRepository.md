# AzDoGitRepository Resource

## Description

The `AzDoGitRepository` DSC resource is used to create and manage Git repositories within Azure DevOps projects. It allows you to define the desired state of a Git repository, including its name and default branch settings.

## Syntax

```powershell
AzDoGitRepository [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    RepositoryName = [String] $RepositoryName
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DefaultBranch = [String] $DefaultBranch ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the project that contains or will contain this repository.

- **RepositoryName** [String] - The name of the Git repository to create or manage.

### Optional Properties

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Repository should exist
  - `'Absent'` - Repository should be removed

- **DefaultBranch** [String] - The default branch for the repository (e.g., 'main', 'master'). This is the branch that will be checked out by default.

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Typically depends on the project existing first.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **RepositoryName** - The name of the repository
- **ProjectName** - The project containing the repository
- **Ensure** - Current state ('Present' or 'Absent')
- **RepositoryId** - The unique identifier of the repository
- **DefaultBranch** - The default branch
- **RepositoryUrl** - The HTTP(S) URL of the repository
- **SshUrl** - The SSH URL of the repository

## Examples

### Example 1: Create a Single Git Repository

```powershell
Configuration CreateGitRepository {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # First create the project
        AzDoProject 'MyProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Then create the repository
        AzDoGitRepository 'MainRepository' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            RepositoryName      = 'MainRepository'
            DefaultBranch       = 'main'
            DependsOn           = '[AzDoProject]MyProject'
        }
    }
}

CreateGitRepository
Start-DscConfiguration -Path ./CreateGitRepository -Wait -Verbose
```

### Example 2: Create Multiple Repositories in a Project

```powershell
Configuration CreateMultipleRepositories {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'CodeProject' {
            Ensure              = 'Present'
            ProjectName         = 'CodeProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Create main repository
        AzDoGitRepository 'Main' {
            Ensure              = 'Present'
            ProjectName         = 'CodeProject'
            RepositoryName      = 'main-app'
            DefaultBranch       = 'main'
            DependsOn           = '[AzDoProject]CodeProject'
        }
        
        # Create development repository
        AzDoGitRepository 'Dev' {
            Ensure              = 'Present'
            ProjectName         = 'CodeProject'
            RepositoryName      = 'dev-environment'
            DefaultBranch       = 'develop'
            DependsOn           = '[AzDoProject]CodeProject'
        }
        
        # Create infrastructure repository
        AzDoGitRepository 'Infrastructure' {
            Ensure              = 'Present'
            ProjectName         = 'CodeProject'
            RepositoryName      = 'infrastructure-as-code'
            DefaultBranch       = 'main'
            DependsOn           = '[AzDoProject]CodeProject'
        }
    }
}

CreateMultipleRepositories
Start-DscConfiguration -Path ./CreateMultipleRepositories -Wait -Verbose
```

### Example 3: Create Repository with Branch Policies

```powershell
Configuration RepositoryWithPolicies {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'SecureProject' {
            Ensure              = 'Present'
            ProjectName         = 'SecureProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Create repository
        AzDoGitRepository 'ProductionRepo' {
            Ensure              = 'Present'
            ProjectName         = 'SecureProject'
            RepositoryName      = 'production'
            DefaultBranch       = 'main'
            DependsOn           = '[AzDoProject]SecureProject'
        }
        
        # Configure branch policy for main branch
        AzDoBranchPolicy 'MainBranchPolicy' {
            RepositoryName      = 'production'
            ProjectName         = 'SecureProject'
            BranchName          = 'main'
            RequireReviewCount  = 2
            AllowSelfApproval   = $false
            DependsOn           = '[AzDoGitRepository]ProductionRepo'
        }
    }
}

RepositoryWithPolicies
Start-DscConfiguration -Path ./RepositoryWithPolicies -Wait -Verbose
```

### Example 4: Using Invoke-DscResource to Get Repository Information

```powershell
# Get current state of a repository
$properties = @{
    ProjectName = 'MyProject'
    RepositoryName = 'MainRepository'
}

$result = Invoke-DscResource -Name 'AzDoGitRepository' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

Write-Host "Repository URL: $($result.RepositoryUrl)"
Write-Host "SSH URL: $($result.SshUrl)"
Write-Host "Default Branch: $($result.DefaultBranch)"
```

### Example 5: Remove a Repository

```powershell
Configuration RemoveRepository {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoGitRepository 'RemoveRepo' {
            Ensure          = 'Absent'
            ProjectName     = 'MyProject'
            RepositoryName  = 'OldRepository'
        }
    }
}

RemoveRepository
Start-DscConfiguration -Path ./RemoveRepository -Wait -Verbose
```

### Example 6: Configure Repository with Settings

```powershell
Configuration RepositoryWithSettings {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'AdvancedProject' {
            Ensure              = 'Present'
            ProjectName         = 'AdvancedProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        AzDoGitRepository 'ConfiguredRepo' {
            Ensure              = 'Present'
            ProjectName         = 'AdvancedProject'
            RepositoryName      = 'configured-app'
            DefaultBranch       = 'main'
            DependsOn           = '[AzDoProject]AdvancedProject'
        }
        
        # Configure repository settings
        AzDoRepositorySettings 'RepoSettings' {
            ProjectName         = 'AdvancedProject'
            RepositoryName      = 'configured-app'
            EnablePrAutocompletion = $true
            DisableComments     = $false
            DependsOn           = '[AzDoGitRepository]ConfiguredRepo'
        }
    }
}

RepositoryWithSettings
Start-DscConfiguration -Path ./RepositoryWithSettings -Wait -Verbose
```

## Important Notes

### Repository Naming

- Repository names must be unique within the project
- Names are case-insensitive for Git but case-sensitive for display
- Use descriptive names for clarity

### Default Branch

- The default branch is used when cloning the repository
- Common conventions: `main` or `master`
- The branch should exist before setting it as default

### Repository URLs

After creation, the repository will have:
- **HTTP(S) URL**: Use for HTTPS-based Git operations
- **SSH URL**: Use for SSH-based Git operations (requires SSH key setup)

### Project Dependency

This resource requires a project to exist first. Always define `DependsOn` to ensure the project is created before the repository.

## Troubleshooting

### Issue: "Project Not Found"

**Cause**: The specified project doesn't exist

**Solution**:
```powershell
# Ensure the project is created first
DependsOn = '[AzDoProject]MyProject'
```

### Issue: "Repository Already Exists"

**Cause**: A repository with the same name already exists in the project

**Solution**:
- Use a unique repository name
- Or ensure the existing repository is removed first

### Issue: "Invalid Default Branch"

**Cause**: The specified default branch doesn't exist

**Solution**:
```powershell
# Use 'main' or 'master' as these are created automatically
DefaultBranch = 'main'
```

## Related Resources

- [AzDoProject](AzDoProject.md) - Create and manage projects
- [AzDoGitPermission](AzDoGitPermission.md) - Manage repository permissions
- [AzDoRepositorySettings](AzDoRepositorySettings.md) - Configure repository settings
- [AzDoBranchPolicy](../Resources/AzDoBranchPolicy.md) - Configure branch policies

## See Also

- [Azure DevOps Git Documentation](https://docs.microsoft.com/en-us/azure/devops/repos/git/)
- [AzureDevOpsDscNative Home](../Home.md)
