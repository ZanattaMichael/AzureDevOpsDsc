# Examples and Scenarios

This page provides practical examples and common scenarios for using AzureDevOpsDscNative.

## Table of Contents

1. [Basic Project Setup](#basic-project-setup)
2. [Complete Project with Teams](#complete-project-with-teams)
3. [Git Repository Configuration](#git-repository-configuration)
4. [Pipeline and CI/CD Setup](#pipeline-and-cicd-setup)
5. [Permission Management](#permission-management)
6. [Artifact Feed Setup](#artifact-feed-setup)
7. [Multi-Project Organization Setup](#multi-project-organization-setup)

## Basic Project Setup

The simplest example: creating a new Azure DevOps project.

```powershell
Configuration BasicProjectSetup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyFirstProject' {
            Ensure               = 'Present'
            ProjectName          = 'MyFirstProject'
            ProjectDescription   = 'My first Azure DevOps project'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
    }
}

# Apply the configuration
BasicProjectSetup
Start-DscConfiguration -Path ./BasicProjectSetup -Wait -Verbose
```

## Complete Project with Teams

Set up a project with teams and team members.

```powershell
Configuration ProjectWithTeams {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Create the project
        AzDoProject 'MyProject' {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            ProjectDescription   = 'Complete project setup'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Scrum'
            Visibility           = 'Private'
        }
        
        # Create development team
        AzDoTeam 'DevelopmentTeam' {
            Ensure              = 'Present'
            TeamName            = 'Development'
            ProjectName         = 'MyProject'
            TeamDescription     = 'Development team members'
            DependsOn           = '[AzDoProject]MyProject'
        }
        
        # Add team members
        AzDoTeamMember 'AddDeveloper1' {
            Ensure              = 'Present'
            TeamName            = 'Development'
            ProjectName         = 'MyProject'
            MemberName          = 'developer1@company.com'
            DependsOn           = '[AzDoTeam]DevelopmentTeam'
        }
        
        AzDoTeamMember 'AddDeveloper2' {
            Ensure              = 'Present'
            TeamName            = 'Development'
            ProjectName         = 'MyProject'
            MemberName          = 'developer2@company.com'
            DependsOn           = '[AzDoTeam]DevelopmentTeam'
        }
        
        # Create QA team
        AzDoTeam 'QATeam' {
            Ensure              = 'Present'
            TeamName            = 'QA'
            ProjectName         = 'MyProject'
            TeamDescription     = 'Quality assurance team'
            DependsOn           = '[AzDoProject]MyProject'
        }
        
        # Add QA team member
        AzDoTeamMember 'AddQATester' {
            Ensure              = 'Present'
            TeamName            = 'QA'
            ProjectName         = 'MyProject'
            MemberName          = 'tester@company.com'
            DependsOn           = '[AzDoTeam]QATeam'
        }
    }
}

ProjectWithTeams
Start-DscConfiguration -Path ./ProjectWithTeams -Wait -Verbose
```

## Git Repository Configuration

Set up Git repositories with permissions and settings.

```powershell
Configuration GitRepositorySetup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Create project
        AzDoProject 'CodeProject' {
            Ensure               = 'Present'
            ProjectName          = 'CodeProject'
            ProjectDescription   = 'Repository management project'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
        
        # Create main repository
        AzDoGitRepository 'MainRepository' {
            Ensure              = 'Present'
            ProjectName         = 'CodeProject'
            RepositoryName      = 'MainRepository'
            DependsOn           = '[AzDoProject]CodeProject'
        }
        
        # Create development repository
        AzDoGitRepository 'DevelopmentRepository' {
            Ensure              = 'Present'
            ProjectName         = 'CodeProject'
            RepositoryName      = 'Development'
            DependsOn           = '[AzDoProject]CodeProject'
        }
        
        # Configure repository permissions
        AzDoGitPermission 'AdminMainRepo' {
            RepositoryName      = 'MainRepository'
            ProjectName         = 'CodeProject'
            IdentityName        = 'Project Admins'
            PermissionName      = 'AdministerRepository'
            Allow               = $true
            DependsOn           = '[AzDoGitRepository]MainRepository'
        }
        
        AzDoGitPermission 'DeveloperMainRepo' {
            RepositoryName      = 'MainRepository'
            ProjectName         = 'CodeProject'
            IdentityName        = 'Developers'
            PermissionName      = 'Contribute'
            Allow               = $true
            DependsOn           = '[AzDoGitRepository]MainRepository'
        }
        
        # Configure branch policy for main branch
        AzDoBranchPolicy 'MainBranchPolicy' {
            RepositoryName      = 'MainRepository'
            ProjectName         = 'CodeProject'
            BranchName          = 'main'
            RequireReviewCount  = 2
            AllowSelfApproval   = $false
            DependsOn           = '[AzDoGitRepository]MainRepository'
        }
        
        # Configure repository settings
        AzDoRepositorySettings 'MainRepoSettings' {
            RepositoryName      = 'MainRepository'
            ProjectName         = 'CodeProject'
            EnablePrAutocompletion = $true
            DependsOn           = '[AzDoGitRepository]MainRepository'
        }
    }
}

GitRepositorySetup
Start-DscConfiguration -Path ./GitRepositorySetup -Wait -Verbose
```

## Pipeline and CI/CD Setup

Set up pipelines with environments and approvals.

```powershell
Configuration PipelineSetup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Create project
        AzDoProject 'PipelineProject' {
            Ensure               = 'Present'
            ProjectName          = 'PipelineProject'
            ProjectDescription   = 'CI/CD pipeline management'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
        
        # Create service connection for deployments
        AzDoServiceConnection 'AzureSubscription' {
            Ensure                      = 'Present'
            ServiceConnectionName       = 'Azure Subscription'
            ProjectName                 = 'PipelineProject'
            ServiceConnectionType       = 'AzureResourceManager'
            SubscriptionId              = 'your-subscription-id'
            SubscriptionName            = 'Your Subscription'
            AuthenticationMethod        = 'ServicePrincipal'
            ServicePrincipalId          = 'your-sp-id'
            ServicePrincipalKey         = 'your-sp-secret'
            TenantId                    = 'your-tenant-id'
            DependsOn                   = '[AzDoProject]PipelineProject'
        }
        
        # Create variable group
        AzDoVariableGroup 'DeploymentVariables' {
            Ensure              = 'Present'
            VariableGroupName   = 'Deployment Variables'
            ProjectName         = 'PipelineProject'
            Variables           = @{
                'Environment' = 'Production'
                'AppName' = 'MyApp'
                'Version' = '1.0.0'
            }
            DependsOn           = '[AzDoProject]PipelineProject'
        }
        
        # Create pipeline environment for Dev
        AzDoPipelineEnvironment 'DevEnvironment' {
            Ensure              = 'Present'
            EnvironmentName     = 'Dev'
            ProjectName         = 'PipelineProject'
            DependsOn           = '[AzDoProject]PipelineProject'
        }
        
        # Create pipeline environment for Production
        AzDoPipelineEnvironment 'ProdEnvironment' {
            Ensure              = 'Present'
            EnvironmentName     = 'Production'
            ProjectName         = 'PipelineProject'
            DependsOn           = '[AzDoProject]PipelineProject'
        }
        
        # Configure approvals for Production environment
        AzDoEnvironmentApproval 'ProdApproval' {
            Ensure              = 'Present'
            EnvironmentName     = 'Production'
            ProjectName         = 'PipelineProject'
            ApproverName        = 'Release Manager'
            DependsOn           = '[AzDoPipelineEnvironment]ProdEnvironment'
        }
        
        # Create pipeline
        AzDoPipeline 'BuildPipeline' {
            Ensure              = 'Present'
            PipelineName        = 'Build and Deploy'
            ProjectName         = 'PipelineProject'
            YamlPath            = 'azure-pipelines.yml'
            DependsOn           = '[AzDoProject]PipelineProject'
        }
    }
}

PipelineSetup
Start-DscConfiguration -Path ./PipelineSetup -Wait -Verbose
```

## Permission Management

Configure comprehensive permission management.

```powershell
Configuration PermissionManagement {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Create organization groups
        AzDoOrganizationGroup 'Developers' {
            Ensure              = 'Present'
            GroupName           = 'Developers'
            GroupDescription    = 'All developers in organization'
        }
        
        AzDoOrganizationGroup 'Administrators' {
            Ensure              = 'Present'
            GroupName           = 'Administrators'
            GroupDescription    = 'Azure DevOps administrators'
        }
        
        AzDoOrganizationGroup 'ReadOnlyUsers' {
            Ensure              = 'Present'
            GroupName           = 'ReadOnly Users'
            GroupDescription    = 'Users with read-only access'
        }
        
        # Create project
        AzDoProject 'SecureProject' {
            Ensure               = 'Present'
            ProjectName          = 'SecureProject'
            ProjectDescription   = 'Project with advanced permissions'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
        
        # Create project groups
        AzDoProjectGroup 'ProjectAdmins' {
            Ensure              = 'Present'
            ProjectName         = 'SecureProject'
            GroupName           = 'Project Admins'
            GroupDescription    = 'Project administrators'
            DependsOn           = '[AzDoProject]SecureProject'
        }
        
        # Grant organization-level permissions
        AzDoGroupPermission 'DeveloperOrgPermissions' {
            GroupName           = 'Developers'
            PermissionName      = 'Create Project'
            Allow               = $true
            DependsOn           = '[AzDoOrganizationGroup]Developers'
        }
        
        AzDoGroupPermission 'AdminOrgPermissions' {
            GroupName           = 'Administrators'
            PermissionName      = 'Administer'
            Allow               = $true
            DependsOn           = '[AzDoOrganizationGroup]Administrators'
        }
        
        # Grant project-level permissions
        AzDoProjectPermission 'AdminProjectPermissions' {
            ProjectName         = 'SecureProject'
            IdentityName        = 'Project Admins'
            PermissionName      'Administer'
            Allow               = $true
            DependsOn           = '[AzDoProject]SecureProject'
        }
        
        AzDoProjectPermission 'DeveloperProjectPermissions' {
            ProjectName         = 'SecureProject'
            IdentityName        = 'Developers'
            PermissionName      = 'Contribute'
            Allow               = $true
            DependsOn           = '[AzDoProject]SecureProject'
        }
        
        AzDoProjectPermission 'ReaderProjectPermissions' {
            ProjectName         = 'SecureProject'
            IdentityName        = 'ReadOnly Users'
            PermissionName      = 'Read'
            Allow               = $true
            DependsOn           = '[AzDoProject]SecureProject'
        }
    }
}

PermissionManagement
Start-DscConfiguration -Path ./PermissionManagement -Wait -Verbose
```

## Artifact Feed Setup

Configure artifact feeds with views and permissions.

```powershell
Configuration ArtifactFeedSetup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Create project
        AzDoProject 'ArtifactProject' {
            Ensure               = 'Present'
            ProjectName          = 'ArtifactProject'
            ProjectDescription   = 'Project for package management'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
        
        # Create artifact feed
        AzDoArtifactFeed 'ProductionFeed' {
            Ensure              = 'Present'
            FeedName            = 'Production'
            ProjectName         = 'ArtifactProject'
            FeedDescription     = 'Production packages'
            DependsOn           = '[AzDoProject]ArtifactProject'
        }
        
        # Create development feed
        AzDoArtifactFeed 'DevelopmentFeed' {
            Ensure              = 'Present'
            FeedName            = 'Development'
            ProjectName         = 'ArtifactProject'
            FeedDescription     = 'Development and testing packages'
            DependsOn           = '[AzDoProject]ArtifactProject'
        }
        
        # Create feed views
        AzDoArtifactFeedView 'ReleaseView' {
            Ensure              = 'Present'
            ViewName            = 'Release'
            FeedName            = 'Production'
            ProjectName         = 'ArtifactProject'
            ViewType            = 'Release'
            DependsOn           = '[AzDoArtifactFeed]ProductionFeed'
        }
        
        AzDoArtifactFeedView 'PreReleaseView' {
            Ensure              = 'Present'
            ViewName            = 'Prerelease'
            FeedName            = 'Production'
            ProjectName         = 'ArtifactProject'
            ViewType            = 'Prerelease'
            DependsOn           = '[AzDoArtifactFeed]ProductionFeed'
        }
        
        # Configure feed permissions
        AzDoArtifactFeedPermission 'DeveloperFeedAccess' {
            FeedName            = 'Development'
            ProjectName         = 'ArtifactProject'
            IdentityName        = 'Developers'
            Role                = 'Contributor'
            DependsOn           = '[AzDoArtifactFeed]DevelopmentFeed'
        }
        
        AzDoArtifactFeedPermission 'EveryoneCanRead' {
            FeedName            = 'Production'
            ProjectName         = 'ArtifactProject'
            IdentityName        = 'Everyone'
            Role                = 'Reader'
            DependsOn           = '[AzDoArtifactFeed]ProductionFeed'
        }
        
        # Configure feed settings
        AzDoArtifactFeedSettings 'ProdFeedSettings' {
            FeedName            = 'Production'
            ProjectName         = 'ArtifactProject'
            HideFromUpstream    = $false
            UpstreamEnabled     = $true
            DependsOn           = '[AzDoArtifactFeed]ProductionFeed'
        }
    }
}

ArtifactFeedSetup
Start-DscConfiguration -Path ./ArtifactFeedSetup -Wait -Verbose
```

## Multi-Project Organization Setup

Set up a complete organization with multiple projects.

```powershell
Configuration MultiProjectOrganization {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Define organization groups
        AzDoOrganizationGroup 'Developers' {
            Ensure              = 'Present'
            GroupName           = 'Developers'
            GroupDescription    = 'Development team members'
        }
        
        AzDoOrganizationGroup 'QAEngineers' {
            Ensure              = 'Present'
            GroupName           = 'QA Engineers'
            GroupDescription    = 'Quality assurance team'
        }
        
        AzDoOrganizationGroup 'ProjectManagers' {
            Ensure              = 'Present'
            GroupName           = 'Project Managers'
            GroupDescription    = 'Project management team'
        }
        
        # Create Frontend project
        AzDoProject 'FrontendProject' {
            Ensure               = 'Present'
            ProjectName          = 'Frontend'
            ProjectDescription   = 'Web frontend development'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
        
        # Create Backend project
        AzDoProject 'BackendProject' {
            Ensure               = 'Present'
            ProjectName          = 'Backend'
            ProjectDescription   = 'Backend services development'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
        
        # Create DevOps project
        AzDoProject 'DevOpsProject' {
            Ensure               = 'Present'
            ProjectName          = 'DevOps'
            ProjectDescription   = 'Infrastructure and DevOps'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
        
        # Add repositories to each project
        AzDoGitRepository 'FrontendRepo' {
            Ensure              = 'Present'
            ProjectName         = 'Frontend'
            RepositoryName      = 'frontend-app'
            DependsOn           = '[AzDoProject]FrontendProject'
        }
        
        AzDoGitRepository 'BackendRepo' {
            Ensure              = 'Present'
            ProjectName         = 'Backend'
            RepositoryName      = 'backend-api'
            DependsOn           = '[AzDoProject]BackendProject'
        }
        
        AzDoGitRepository 'InfrastructureRepo' {
            Ensure              = 'Present'
            ProjectName         = 'DevOps'
            RepositoryName      = 'infrastructure'
            DependsOn           = '[AzDoProject]DevOpsProject'
        }
        
        # Create variable groups per project
        AzDoVariableGroup 'FrontendVars' {
            Ensure              = 'Present'
            VariableGroupName   = 'Frontend Variables'
            ProjectName         = 'Frontend'
            Variables           = @{
                'NodeVersion' = '18.x'
                'NpmRegistry' = 'https://registry.npmjs.org'
            }
            DependsOn           = '[AzDoProject]FrontendProject'
        }
        
        AzDoVariableGroup 'BackendVars' {
            Ensure              = 'Present'
            VariableGroupName   = 'Backend Variables'
            ProjectName         = 'Backend'
            Variables           = @{
                'DotNetVersion' = '7.0'
                'ApiPort' = '5000'
            }
            DependsOn           = '[AzDoProject]BackendProject'
        }
    }
}

MultiProjectOrganization
Start-DscConfiguration -Path ./MultiProjectOrganization -Wait -Verbose
```

## Using Configuration Data

Use configuration data files for environment-specific settings:

```powershell
# ConfigurationData.psd1
@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
        },
        @{
            NodeName = 'localhost'
            Environment = 'Development'
            Projects = @(
                @{ Name = 'DevProject1'; Template = 'Agile' },
                @{ Name = 'DevProject2'; Template = 'Agile' }
            )
        },
        @{
            NodeName = 'localhost'
            Environment = 'Production'
            Projects = @(
                @{ Name = 'ProdProject1'; Template = 'Scrum' },
                @{ Name = 'ProdProject2'; Template = 'Scrum' }
            )
        }
    )
}

# Configuration.ps1
Configuration EnvironmentAwareSetup {
    param([hashtable]$ConfigurationData)
    
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node $AllNodes.NodeName {
        foreach ($project in $Node.Projects) {
            AzDoProject "Project_$($project.Name)" {
                Ensure              = 'Present'
                ProjectName         = $project.Name
                SourceControlType   = 'Git'
                ProcessTemplate     = $project.Template
                Visibility          = 'Private'
            }
        }
    }
}

# Apply configuration
$data = Import-PowerShellDataFile -Path ConfigurationData.psd1
EnvironmentAwareSetup -ConfigurationData $data
```

## Common Patterns

### Pattern: Complete New Project Setup

```powershell
function New-AzureDevOpsProject {
    param(
        [string]$ProjectName,
        [string]$Description,
        [string]$ProcessTemplate = 'Agile'
    )
    
    Configuration CreateCompleteProject {
        Import-DscResource -ModuleName 'AzureDevOpsDscNative'
        
        Node localhost {
            AzDoProject $ProjectName {
                Ensure               = 'Present'
                ProjectName          = $ProjectName
                ProjectDescription   = $Description
                SourceControlType    = 'Git'
                ProcessTemplate      = $ProcessTemplate
                Visibility           = 'Private'
            }
            
            AzDoGitRepository "${ProjectName}Repo" {
                Ensure              = 'Present'
                ProjectName         = $ProjectName
                RepositoryName      = "$($ProjectName)-repo"
                DependsOn           = "[AzDoProject]$ProjectName"
            }
        }
    }
    
    CreateCompleteProject
    Start-DscConfiguration -Path ./CreateCompleteProject -Wait -Verbose
}

# Usage
New-AzureDevOpsProject -ProjectName 'MyNewProject' -Description 'New project' -ProcessTemplate 'Agile'
```

### Pattern: Apply Configuration Across Multiple Projects

```powershell
$projectNames = @('Frontend', 'Backend', 'DevOps', 'Infrastructure')

Configuration ApplyToMultipleProjects {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        foreach ($projectName in $projectNames) {
            AzDoVariableGroup "VarGroup_$projectName" {
                Ensure              = 'Present'
                VariableGroupName   = 'Common Variables'
                ProjectName         = $projectName
                Variables           = @{
                    'CompanyName' = 'MyCompany'
                    'Environment' = 'Production'
                }
            }
        }
    }
}

ApplyToMultipleProjects
Start-DscConfiguration -Path ./ApplyToMultipleProjects -Wait -Verbose
```

## Tips and Tricks

1. **Test First**: Always test configurations in a non-production environment
2. **Use Verbose**: Run with `-Verbose` for detailed output
3. **Dependencies**: Clearly define dependencies with `DependsOn`
4. **Idempotency**: Ensure all configurations can run multiple times safely
5. **Error Handling**: Implement proper error handling in production
6. **Logging**: Enable DSC logging for troubleshooting
7. **Documentation**: Document all custom configurations
8. **Version Control**: Keep configurations in version control
9. **Backup**: Regular backups of configurations and credentials
10. **Monitoring**: Monitor configuration compliance regularly
