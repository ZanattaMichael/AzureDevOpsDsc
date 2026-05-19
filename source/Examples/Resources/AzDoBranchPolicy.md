# DSC AzDoBranchPolicy Resource

# Syntax

``` PowerShell
AzDoBranchPolicy [string] #ResourceName
{
    ProjectName      = [String]$ProjectName
    RepositoryName   = [String]$RepositoryName
    BranchName       = [String]$BranchName
    PolicyType       = [String]$PolicyType
    [ isEnabled      = [Boolean]$isEnabled ]
    [ isBlocking     = [Boolean]$isBlocking ]
    [ PolicySettings = [HashTable]$PolicySettings ]
    [ Ensure         = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __RepositoryName__: The name of the Git repository. This is a key property.
- __BranchName__: The branch to apply the policy to, in `refs/heads/` format (e.g., `refs/heads/main`). This is a key property.
- __PolicyType__: The type of branch policy to apply (e.g., `MinimumReviewerCount`, `CommentRequirements`, `MergeStrategy`).
- __isEnabled__: Whether the policy is enabled. Defaults to `$true`.
- __isBlocking__: Whether the policy blocks pull request completion. Defaults to `$true`.
- __PolicySettings__: A hashtable of policy-specific settings.
- __Ensure__: Specifies whether the policy should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Common Policy Types and Their Settings

### MinimumReviewerCount
``` PowerShell
PolicySettings = @{
    minimumApproverCount = 2
    creatorVoteCounts    = $false
    allowDownvotes       = $false
    resetOnSourcePush    = $true
}
```

### CommentRequirements
``` PowerShell
PolicySettings = @{
    # No additional settings required
}
```

### MergeStrategy
``` PowerShell
PolicySettings = @{
    allowSquash        = $true
    allowNoFastForward = $false
    allowRebase        = $false
    allowRebaseMerge   = $false
}
```

# Additional Information

This resource manages branch policies in Azure DevOps Git repositories, enforcing code quality standards such as requiring minimum reviewers, resolving comments, or restricting merge strategies.

# Examples

## Example 1: Require minimum reviewers on main branch

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoBranchPolicy 'AddBranchPolicy' {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
            BranchName     = 'refs/heads/main'
            PolicyType     = 'MinimumReviewerCount'
            isEnabled      = $true
            isBlocking     = $true
            PolicySettings = @{
                minimumApproverCount = 2
                creatorVoteCounts    = $false
            }
        }
    }
}
```

## Example 2: Remove a branch policy

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoBranchPolicy 'RemoveBranchPolicy' {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
            BranchName     = 'refs/heads/main'
            PolicyType     = 'MinimumReviewerCount'
        }
    }
}
```
