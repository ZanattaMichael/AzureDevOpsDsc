# DSC AzDoEnvironmentApproval Resource

# Syntax

``` PowerShell
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

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __EnvironmentName__: The name of the pipeline environment. This is a key property.
- __Approvers__: An array of user UPNs or group names who must approve deployments. This is a mandatory property.
- __RequiredApproverCount__: The minimum number of approvals required. Defaults to `1`.
- __AllowApproverToSelf__: Whether the user who triggered the pipeline can approve their own deployment. Defaults to `$false`.
- __TimeoutInMinutes__: How long the approval check waits before timing out. Defaults to `43200` (30 days).
- __Instructions__: Instructions shown to approvers. Optional.
- __Ensure__: Specifies whether the approval check should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource configures approval gates on Azure DevOps pipeline environments. When an approval check is configured, deployments to that environment will pause until the required number of approvers have approved the deployment.

# Examples

## Example 1: Require one approver for production

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoEnvironmentApproval 'AddApproval' {
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
```

## Example 2: Require multiple approvers

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoEnvironmentApproval 'AddMultiApproval' {
            Ensure                = 'Present'
            ProjectName           = 'MyProject'
            EnvironmentName       = 'Production'
            Approvers             = @('approver1@example.com', 'approver2@example.com')
            RequiredApproverCount = 2
            AllowApproverToSelf   = $false
            TimeoutInMinutes      = 2880
        }
    }
}
```
