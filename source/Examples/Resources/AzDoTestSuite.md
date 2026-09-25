# DSC AzDoTestSuite Resource

## Syntax

```PowerShell
AzDoTestSuite [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    PlanName               = [String]$PlanName
    Path                   = [String]$Path
    [ SuiteType            = [String] {'StaticTestSuite', 'DynamicTestSuite', 'RequirementTestSuite'} ]
    [ Wiql                 = [String]$Wiql ]
    [ RequirementIds       = [Int32[]]$RequirementIds ]
    [ AllowRecursiveDelete = [Boolean]$AllowRecursiveDelete ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **PlanName**: The name of the test plan the suite belongs to. Mandatory.
- **Path**: The suite's path under the plan's root suite, for example `Regression/Smoke`. This is the key property. Backslashes are accepted and normalized to forward slashes.
- **SuiteType**: The kind of suite: `StaticTestSuite`, `DynamicTestSuite` or `RequirementTestSuite`. Defaults to `StaticTestSuite`. Immutable after creation - Azure DevOps has no API to change a suite's type, so `Test()` reports an error rather than drift if the configuration disagrees with the live suite.
- **Wiql**: The WIQL that selects the suite's test cases. Only meaningful for a `DynamicTestSuite`. Compared normalized (the API re-indents and re-cases WIQL on return) but always written back exactly as supplied.
- **RequirementIds**: The work item ids of the requirements the suite tracks. Only meaningful for a `RequirementTestSuite`. Compared as a set.
- **AllowRecursiveDelete**: Permits removal of a suite that still has children. Defaults to `$false`.
- **Ensure**: Specifies whether the suite should exist. Valid values are `Present` and `Absent`.

## Additional Information

Suites are identified by their path of suite names under the plan's root suite, the same way `AzDoQueryFolder` treats query folder paths. The resource deliberately does not create its own ancestry - declare each ancestor suite as its own `AzDoTestSuite` resource and chain descendants with `DependsOn`.

A `StaticTestSuite` has no query - it holds test cases added directly. A `DynamicTestSuite`'s membership is computed from `Wiql`. A `RequirementTestSuite` tracks a fixed set of requirement work items via `RequirementIds`.

Deleting a suite deletes every suite beneath it. Removal of a suite that still has children is refused unless `AllowRecursiveDelete` is set to `$true`.

There is no dedicated test-plan security namespace. "Manage test plans" and "Manage test suites" are permissions on the `CSS` (area path) security namespace, which `AzDoAreaPermission` already manages - there is no `AzDoTestSuitePermission` resource.

## Examples

## Example 1: Sample Configuration using AzDoTestSuite Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoTestSuite Regression {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            PlanName    = 'Sprint 1 Regression'
            Path        = 'Regression'
            SuiteType   = 'StaticTestSuite'
        }

        AzDoTestSuite Smoke {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            PlanName    = 'Sprint 1 Regression'
            Path        = 'Regression/Smoke'
            SuiteType   = 'StaticTestSuite'
            DependsOn   = '[AzDoTestSuite]Regression'
        }

        AzDoTestSuite ActiveBugs {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            PlanName    = 'Sprint 1 Regression'
            Path        = 'Regression/Active Bugs'
            SuiteType   = 'DynamicTestSuite'
            Wiql        = "SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active'"
            DependsOn   = '[AzDoTestSuite]Regression'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoTestSuite
$properties = @{
    ProjectName = 'MyProject'
    PlanName    = 'Sprint 1 Regression'
    Path        = 'Regression/Smoke'
}

Invoke-DscResource -Name 'AzDoTestSuite' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Regression Suite
  type: AzureDevOpsDscNative/AzDoTestSuite
  dependsOn:
    - AzureDevOpsDscNative/AzDoTestPlan/Sprint 1 Regression Test Plan
  properties:
    ProjectName: $ProjectName
    PlanName: Sprint 1 Regression
    Path: Regression
    SuiteType: StaticTestSuite
    Ensure: Present

- name: Smoke Suite
  type: AzureDevOpsDscNative/AzDoTestSuite
  dependsOn:
    - AzureDevOpsDscNative/AzDoTestSuite/Regression Suite
  properties:
    ProjectName: $ProjectName
    PlanName: Sprint 1 Regression
    Path: Regression/Smoke
    SuiteType: StaticTestSuite
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
