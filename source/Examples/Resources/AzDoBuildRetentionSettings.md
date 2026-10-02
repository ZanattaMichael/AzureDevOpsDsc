# DSC AzDoBuildRetentionSettings Resource

## Syntax

```PowerShell
AzDoBuildRetentionSettings [string] #ResourceName
{
    ProjectName                            = [String]$ProjectName
    [ DaysToKeepRuns                       = [Int32] ]
    [ DaysToKeepArtifacts                  = [Int32] ]
    [ DaysToKeepPullRequestRuns            = [Int32] ]
    [ RunsToRetainPerProtectedBranch       = [Int32] ]
    [ Ensure                               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **DaysToKeepRuns**: The number of days to keep pipeline runs before they are purged (API field `purgeRuns` when read, `runRetention` when written).
- **DaysToKeepArtifacts**: The number of days to keep build artifacts, symbols and attachments before they are purged (API field `purgeArtifacts` when read, `artifactsRetention` when written).
- **DaysToKeepPullRequestRuns**: The number of days to keep runs triggered by pull requests before they are purged (API field `purgePullRequestRuns` when read, `pullRequestRunRetention` when written).
- **RunsToRetainPerProtectedBranch**: The minimum number of runs to always retain per protected branch, regardless of age (API field `retainRunsPerProtectedBranch`, the same when read and written).
- **Ensure**: Specifies the desired state. These settings are intrinsic to a project and cannot be removed, so `Absent` is a no-op.

Each setting is unmanaged unless you specify it - an omitted property is left untouched rather
than compared or overwritten. Every specified value is validated against the organization's own
live `min`/`max` bounds for that setting (read from `_apis/build/retention`, never hard-coded); a
value outside that range is refused and never written.

## Additional Information

This resource manages a project's run and artifact retention policy (Project Settings → Pipelines
→ Settings → Retention) via the Build REST API (`_apis/build/retention`).

**Out of scope:** the classic-pipeline-era *maximum retention policy* and *default retention
policy* values exposed at `_apis/build/settings` are not managed by this resource. They apply only
to the classic build/release pipeline experience, which is being retired alongside classic release
management (see `docs/ResourceRoadmap.md`, and issue #86).

## Examples

## Example 1: Sample Configuration using AzDoBuildRetentionSettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoBuildRetentionSettings ProjectRetention {
            Ensure                         = 'Present'
            ProjectName                    = 'MyProject'
            DaysToKeepRuns                 = 30
            DaysToKeepArtifacts            = 14
            DaysToKeepPullRequestRuns      = 10
            RunsToRetainPerProtectedBranch = 3
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoBuildRetentionSettings
$properties = @{
    ProjectName    = 'MyProject'
    DaysToKeepRuns = 30
}

Invoke-DscResource -Name 'AzDoBuildRetentionSettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Project run/artifact retention
  type: AzureDevOpsDscNative/AzDoBuildRetentionSettings
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    DaysToKeepRuns: 30
    DaysToKeepArtifacts: 14
    DaysToKeepPullRequestRuns: 10
    RunsToRetainPerProtectedBranch: 3
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
