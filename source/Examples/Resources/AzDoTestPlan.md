# DSC AzDoTestPlan Resource

## Syntax

```PowerShell
AzDoTestPlan [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    Name                   = [String]$Name
    [ AreaPath             = [String]$AreaPath ]
    [ Iteration            = [String]$Iteration ]
    [ Owner                = [String]$Owner ]
    [ StartDate            = [String]$StartDate ]
    [ EndDate              = [String]$EndDate ]
    [ State                = [String] {'Active', 'Inactive'} ]
    [ BuildDefinitionId    = [Int32]$BuildDefinitionId ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **Name**: The name of the test plan. This is the key property.
- **AreaPath**: The area path new test cases are assigned to by default.
- **Iteration**: The iteration path the plan is scoped to.
- **Owner**: The user or group who owns the plan. Resolved via `Find-AzDoIdentity` the same way other resources resolve identity strings (UPN, `'[Project]\Group'`, or display name).
- **StartDate**: The date testing is scheduled to start.
- **EndDate**: The date testing is scheduled to end.
- **State**: The plan's state: `Active` or `Inactive`.
- **BuildDefinitionId**: The numeric id of the build pipeline used to identify the build under test for automated runs. Optional - omit for a plan with no associated build pipeline.
- **Ensure**: Specifies whether the plan should exist. Valid values are `Present` and `Absent`.

## Additional Information

There is no dedicated test-plan security namespace. "Manage test plans" and "Manage test suites" are permissions on the `CSS` (area path) security namespace, which `AzDoAreaPermission` already manages - there is no `AzDoTestPlanPermission` resource.

Creating or updating a test plan requires the DSC identity to have Basic access plus a Test Plans license/access level in the organization. Integration tests detect a licensing or access refusal up front and skip with a reason rather than failing.

## Examples

## Example 1: Sample Configuration using AzDoTestPlan Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoTestPlan SprintOne {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Name        = 'Sprint 1 Regression'
            AreaPath    = 'MyProject'
            Iteration   = 'MyProject\Sprint 1'
            Owner       = 'user@domain.com'
            State       = 'Active'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoTestPlan
$properties = @{
    ProjectName = 'MyProject'
    Name        = 'Sprint 1 Regression'
}

Invoke-DscResource -Name 'AzDoTestPlan' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Sprint 1 Regression Test Plan
  type: AzureDevOpsDscNative/AzDoTestPlan
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    Name: Sprint 1 Regression
    AreaPath: $ProjectName
    State: Active
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
