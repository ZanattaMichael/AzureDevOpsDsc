# DSC AzDoEnvironmentApproval Resource

## Syntax

```PowerShell
AzDoEnvironmentApproval [string] #ResourceName
{
    ProjectName               = [String]$ProjectName
    EnvironmentName           = [String]$EnvironmentName
    Approvers                 = [String[]]$Approvers
    [ RequiredApproverCount   = [UInt32]$RequiredApproverCount ]
    [ AllowApproverToSelf     = [Boolean]$AllowApproverToSelf ]
    [ TimeoutInMinutes        = [UInt32]$TimeoutInMinutes ]
    [ Instructions            = [String]$Instructions ]
    [ Ensure                  = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **EnvironmentName**: The name of the pipeline environment. This is a key property.
- **Approvers**: An array of user UPNs or group names who must approve deployments. This is a mandatory property.
- **RequiredApproverCount**: The minimum number of approvals required. Defaults to `1`.
- **AllowApproverToSelf**: Whether the user who triggered the pipeline can approve their own deployment. Defaults to `$false`.
- **TimeoutInMinutes**: How long the approval check waits before timing out. Defaults to `43200` (30 days).
- **Instructions**: Instructions shown to approvers. Optional.
- **Ensure**: Specifies whether the approval check should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource configures approval gates on Azure DevOps pipeline environments. When an approval check is configured, deployments to that environment will pause until the required number of approvers have approved the deployment.

## Examples

## Example 1: Sample Configuration using AzDoEnvironmentApproval Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoEnvironmentApproval AddApproval {
            Ensure                = 'Present'
            ProjectName           = 'MyProject'
            EnvironmentName       = 'Production'
            Approvers             = @('approver@example.com')
            RequiredApproverCount = 1
            AllowApproverToSelf   = $false
            TimeoutInMinutes      = 1440
            Instructions          = 'Please review the deployment plan before approving.'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoEnvironmentApproval
$properties = @{
    ProjectName     = 'MyProject'
    EnvironmentName = 'Production'
    Approvers       = @('approver@example.com')
}

Invoke-DscResource -Name 'AzDoEnvironmentApproval' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  EnvironmentName: Production
}

resources:
- name: Production Approval Gate
  type: AzureDevOpsDsc/AzDoEnvironmentApproval
  dependsOn:
    - AzureDevOpsDsc/AzDoPipelineEnvironment/Production
  properties:
    ProjectName: $ProjectName
    EnvironmentName: $EnvironmentName
    Approvers:
      - approver@example.com
    RequiredApproverCount: 1
    AllowApproverToSelf: false
    TimeoutInMinutes: 1440
    Instructions: Please review the deployment plan before approving.
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
