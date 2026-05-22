# DSC AzDoBranchPolicy Resource

## Syntax

```PowerShell
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

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **RepositoryName**: The name of the Git repository. This is a key property.
- **BranchName**: The branch to apply the policy to, in `refs/heads/` format (e.g., `refs/heads/main`). This is a key property.
- **PolicyType**: The type of branch policy to apply (e.g., `MinimumReviewerCount`, `CommentRequirements`, `MergeStrategy`). This is a key property.
- **isEnabled**: Whether the policy is enabled. Defaults to `$true`.
- **isBlocking**: Whether the policy blocks pull request completion. Defaults to `$true`.
- **PolicySettings**: A hashtable of policy-specific settings.
- **Ensure**: Specifies whether the policy should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages branch policies in Azure DevOps Git repositories, enforcing code quality standards such as requiring minimum reviewers, resolving comments, or restricting merge strategies.

## Examples

## Example 1: Sample Configuration using AzDoBranchPolicy Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoBranchPolicy AddBranchPolicy {
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

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoBranchPolicy
$properties = @{
    ProjectName    = 'MyProject'
    RepositoryName = 'MyRepository'
    BranchName     = 'refs/heads/main'
    PolicyType     = 'MinimumReviewerCount'
}

Invoke-DscResource -Name 'AzDoBranchPolicy' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: Main Branch Minimum Reviewer Policy
  type: AzureDevOpsDsc/AzDoBranchPolicy
  dependsOn:
    - AzureDevOpsDsc/AzDoGitRepository/MyRepository
  properties:
    ProjectName: $ProjectName
    RepositoryName: $RepositoryName
    BranchName: refs/heads/main
    PolicyType: MinimumReviewerCount
    isEnabled: true
    isBlocking: true
    PolicySettings:
      minimumApproverCount: 2
      creatorVoteCounts: false
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
