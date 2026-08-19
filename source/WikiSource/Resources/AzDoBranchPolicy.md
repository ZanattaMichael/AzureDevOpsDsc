# AzDoBranchPolicy Resource

## Description

The `AzDoBranchPolicy` DSC resource is used to configure and manage branch policies for Git repositories in Azure DevOps. Branch policies help enforce code quality, review processes, and security practices by requiring approval, requiring specific reviewers, running builds, or enforcing other checks before code can be merged into protected branches.

## Syntax

```powershell
AzDoBranchPolicy [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    RepositoryName = [String] $RepositoryName
    BranchName = [String] $BranchName
    PolicyType = [String] $PolicyType
    [ isEnabled = [Boolean] $isEnabled ]
    [ isBlocking = [Boolean] $isBlocking ]
    [ PolicySettings = [HashTable] $PolicySettings ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

- **RepositoryName** [String] - The name of the Git repository.

- **BranchName** [String] - The branch ref name (e.g., 'refs/heads/main', 'refs/heads/develop').

- **PolicyType** [String] - The type of branch policy to apply (e.g., 'MinimumReviewerCount', 'RequiredReviewers', 'WorkItemLinking', 'BuildValidation', 'Status').

### Optional Properties

- **isEnabled** [Boolean] - Whether the policy is enabled. Default is `$true`.

- **isBlocking** [Boolean] - Whether the policy is blocking (prevents merge if not satisfied). Default is `$true`.

- **PolicySettings** [HashTable] - Policy-type-specific settings (e.g., reviewer count, build definition ID). Contents depend on PolicyType.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Policy should exist
  - `'Absent'` - Policy should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **RepositoryName** - The name of the repository
- **BranchName** - The branch name
- **PolicyType** - The type of policy applied
- **isEnabled** - Whether the policy is enabled
- **isBlocking** - Whether the policy is blocking
- **PolicySettings** - The policy-specific settings
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Require Minimum Reviewers

```powershell
Configuration RequireReviewers {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoBranchPolicy 'MainMinReviewers' {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            BranchName       = 'refs/heads/main'
            PolicyType       = 'MinimumReviewerCount'
            isEnabled        = $true
            isBlocking       = $true
            PolicySettings   = @{
                MinimumApproverCount = 2
                CreatorVoteCounts    = $false
                AllowDownvotes       = $false
                ResetOnPush          = $true
            }
            Ensure           = 'Present'
        }
    }
}

RequireReviewers
Start-DscConfiguration -Path ./RequireReviewers -Wait -Verbose
```

### Example 2: Require Build Validation

```powershell
Configuration RequireBuildValidation {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoBranchPolicy 'MainBuildPolicy' {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            BranchName       = 'refs/heads/main'
            PolicyType       = 'BuildValidation'
            isEnabled        = $true
            isBlocking       = $true
            PolicySettings   = @{
                DefinitionId = 1
                Scope        = 'refs/heads/main'
                DisplayName  = 'CI Build'
            }
            Ensure           = 'Present'
        }
    }
}

RequireBuildValidation
Start-DscConfiguration -Path ./RequireBuildValidation -Wait -Verbose
```

### Example 3: Configure Multiple Branch Policies

```powershell
Configuration MultipleBranchPolicies {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoBranchPolicy 'MainReviewPolicy' {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            BranchName       = 'refs/heads/main'
            PolicyType       = 'MinimumReviewerCount'
            isEnabled        = $true
            isBlocking       = $true
            PolicySettings   = @{
                MinimumApproverCount = 2
                CreatorVoteCounts    = $false
            }
            Ensure           = 'Present'
        }
        
        AzDoBranchPolicy 'MainBuildPolicy' {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            BranchName       = 'refs/heads/main'
            PolicyType       = 'BuildValidation'
            isEnabled        = $true
            isBlocking       = $true
            PolicySettings   = @{
                DefinitionId = 1
            }
            Ensure           = 'Present'
        }
        
        AzDoBranchPolicy 'DevelopMinReviewers' {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            BranchName       = 'refs/heads/develop'
            PolicyType       = 'MinimumReviewerCount'
            isEnabled        = $true
            isBlocking       = $false
            PolicySettings   = @{
                MinimumApproverCount = 1
            }
            Ensure           = 'Present'
        }
    }
}

MultipleBranchPolicies
Start-DscConfiguration -Path ./MultipleBranchPolicies -Wait -Verbose
```

### Example 4: Query Current Branch Policies

```powershell
# Get the current state of a branch policy
$properties = @{
    ProjectName    = 'MyProject'
    RepositoryName = 'MyRepository'
    BranchName     = 'refs/heads/main'
    PolicyType     = 'MinimumReviewerCount'
}

$result = Invoke-DscResource -Name 'AzDoBranchPolicy' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, RepositoryName, BranchName, PolicyType, isEnabled, isBlocking
```

### Example 5: Require Work Item Linking

```powershell
Configuration RequireWorkItemLinking {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoBranchPolicy 'MainWorkItemPolicy' {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            BranchName       = 'refs/heads/main'
            PolicyType       = 'WorkItemLinking'
            isEnabled        = $true
            isBlocking       = $true
            PolicySettings   = @{
                RequiredWorkItemType = 'Bug,Task,Feature'
            }
            Ensure           = 'Present'
        }
    }
}

RequireWorkItemLinking
Start-DscConfiguration -Path ./RequireWorkItemLinking -Wait -Verbose
```

### Example 6: Disable a Branch Policy

```powershell
Configuration DisableBranchPolicy {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoBranchPolicy 'DisabledPolicy' {
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            BranchName       = 'refs/heads/main'
            PolicyType       = 'MinimumReviewerCount'
            isEnabled        = $false
            Ensure           = 'Present'
        }
    }
}

DisableBranchPolicy
Start-DscConfiguration -Path ./DisableBranchPolicy -Wait -Verbose
```

## Important Notes

### Policy Types

- **MinimumReviewerCount** - Requires a minimum number of code reviewers
- **BuildValidation** - Requires a successful build before merging
- **RequiredReviewers** - Requires approval from specific reviewers
- **WorkItemLinking** - Requires linking to work items
- **Status** - Requires specific status checks to pass
- **Comment Requirements** - Requires resolution of comments

### Branch Ref Format

- Format: `refs/heads/branchname` (e.g., `refs/heads/main`, `refs/heads/develop`)
- Can use wildcards for multiple branches
- Exact branch names are required

### Blocking vs Non-Blocking

- **Blocking policies** prevent merge until satisfied
- **Non-blocking policies** provide warnings but allow merge
- Critical policies should always be blocking

### Best Practices

- Require reviewers on main/master branches
- Require build validation for all branches
- Use non-blocking policies for soft requirements
- Document policy purposes for developers

## Troubleshooting

### Issue: "Repository Not Found"

**Cause**: The repository does not exist in the project

**Solution**:
```powershell
# Verify repository name matches exactly
# Ensure repository exists before applying policies
# Use AzDoGitRepository to create repository first
```

### Issue: "Invalid Policy Settings"

**Cause**: Policy-specific settings are incorrect for the policy type

**Solution**:
- Verify policy settings match the policy type
- Check required vs optional settings for each policy type
- Ensure numeric values are in valid ranges

### Issue: "Branch Policy Not Enforced"

**Cause**: Policy may not be blocking or is disabled

**Solution**:
```powershell
# Set isBlocking to $true to enforce the policy
# Verify isEnabled is $true
# Check policy scope includes the target branch
```

## Related Resources

- [AzDoGitRepository](AzDoGitRepository) - Manage Git repositories
- [AzDoGitPermission](AzDoGitPermission) - Manage Git repository permissions
- [AzDoPipeline](AzDoPipeline) - Create build pipelines for validation

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
