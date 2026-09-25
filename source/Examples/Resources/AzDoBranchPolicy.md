# DSC AzDoBranchPolicy Resource

## Syntax

```PowerShell
AzDoBranchPolicy [string] #ResourceName
{
    ProjectName        = [String]$ProjectName
    PolicyType         = [String]$PolicyType
    [ RepositoryName   = [String]$RepositoryName ]
    [ BranchName       = [String]$BranchName ]
    [ PolicyIdentifier = [String]$PolicyIdentifier ]
    [ MatchKind        = [String] {'Exact', 'Prefix'} ]
    [ isEnabled        = [Boolean]$isEnabled ]
    [ isBlocking       = [Boolean]$isBlocking ]
    [ PolicySettings   = [HashTable]$PolicySettings ]
    [ Ensure           = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This is the resource's only key property.
- **PolicyType**: The type of branch policy to apply (e.g., `MinimumReviewerCount`, `CommentRequirements`, `MergeStrategy`, `BuildValidation`, `StatusCheck`). This property is mandatory.
- **RepositoryName**: The name of the Git repository. Leave empty for a cross-repository policy scope that applies to every repository in the project.
- **BranchName**: The branch to apply the policy to, in `refs/heads/` format (e.g., `refs/heads/main`) or without the prefix. Leave empty for a repository-wide policy scope with no branch restriction - only meaningful for policy types that do not require a ref, such as the repository settings policies.
- **PolicyIdentifier**: Optional. Azure DevOps allows several policies of the same `PolicyType` in the same scope (two build validation policies pointing at different pipelines, several status checks), but this resource has exactly one key property (`ProjectName`). Set this to a value that appears among that policy's `PolicySettings` - a build definition id, a status check's name, a required reviewer's display name - to tell the policies apart. Left unset, the first policy of that type found in the scope is used, which is unchanged from before this property existed.
- **MatchKind**: Optional. `Exact` (the default) matches `BranchName` as one branch. `Prefix` matches every branch whose ref name starts with `BranchName` (e.g. `release/` matches every `release/*` branch).
- **isEnabled**: Whether the policy is enabled. Defaults to `$true`.
- **isBlocking**: Whether the policy blocks pull request completion. Defaults to `$true`.
- **PolicySettings**: A hashtable of policy-specific settings. Only the keys present here are compared for drift; a key not stated is left alone. A `scope` key, if supplied, overrides the scope this resource would otherwise build from `RepositoryName`/`BranchName`/`MatchKind`.
- **Ensure**: Specifies whether the policy should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages branch policies in Azure DevOps Git repositories, enforcing code quality standards such as requiring minimum reviewers, resolving comments, or restricting merge strategies. Drift is detected on whichever `PolicySettings` keys the configuration states, not just `isEnabled`/`isBlocking`, and several policies of the same type can coexist in one scope by giving each a distinct `PolicyIdentifier`.

## Examples

## Example 1: Sample Configuration using AzDoBranchPolicy Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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

Invoke-DscResource -Name 'AzDoBranchPolicy' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: Main Branch Minimum Reviewer Policy
  type: AzureDevOpsDscNative/AzDoBranchPolicy
  dependsOn:
    - AzureDevOpsDscNative/AzDoGitRepository/MyRepository
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

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
