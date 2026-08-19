# AzDoEnvironmentApproval Resource

## Description

The `AzDoEnvironmentApproval` DSC resource is used to configure approval checks for deployment environments in Azure DevOps release pipelines. It allows you to specify which users or groups must approve deployments to specific environments, set approval requirements, and configure timeout and notification settings for approval requests.

## Syntax

```powershell
AzDoEnvironmentApproval [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    EnvironmentName = [String] $EnvironmentName
    Approvers = [String[]] $Approvers
    [ RequiredApproverCount = [UInt32] $RequiredApproverCount ]
    [ AllowApproverToSelf = [Boolean] $AllowApproverToSelf ]
    [ TimeoutInMinutes = [UInt32] $TimeoutInMinutes ]
    [ Instructions = [String] $Instructions ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

- **EnvironmentName** [String] - The name of the deployment environment.

- **Approvers** [String[]] - An array of user email addresses or group names who can approve deployments.

### Optional Properties

- **RequiredApproverCount** [UInt32] - The number of approvals required before deployment. Default is `1`.

- **AllowApproverToSelf** [Boolean] - Whether the user requesting deployment can approve their own request. Default is `$false`.

- **TimeoutInMinutes** [UInt32] - The timeout duration for approval requests in minutes. Default is `43200` (30 days).

- **Instructions** [String] - Additional instructions or notes to display when requesting approvals.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Approval check should exist
  - `'Absent'` - Approval check should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **EnvironmentName** - The name of the environment
- **Approvers** - The list of approvers
- **RequiredApproverCount** - The number of required approvers
- **AllowApproverToSelf** - Whether self-approval is allowed
- **TimeoutInMinutes** - The approval timeout in minutes
- **Instructions** - Approval instructions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Configure Single Approver for Environment

```powershell
Configuration SingleApproverEnvironment {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoEnvironmentApproval 'ProdApproval' {
            ProjectName         = 'MyProject'
            EnvironmentName     = 'Production'
            Approvers           = @('release-manager@company.com')
            RequiredApproverCount = 1
            AllowApproverToSelf = $false
            TimeoutInMinutes    = 1440
            Instructions        = 'Approve only for planned deployments'
            Ensure              = 'Present'
        }
    }
}

SingleApproverEnvironment
Start-DscConfiguration -Path ./SingleApproverEnvironment -Wait -Verbose
```

### Example 2: Require Multiple Approvals

```powershell
Configuration MultipleApprovalsRequired {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoEnvironmentApproval 'CriticalProdApproval' {
            ProjectName         = 'MyProject'
            EnvironmentName     = 'Production'
            Approvers           = @(
                'release-manager@company.com',
                'ops-lead@company.com',
                'security-team@company.com'
            )
            RequiredApproverCount = 2
            AllowApproverToSelf   = $false
            TimeoutInMinutes      = 2880
            Instructions          = 'Two approvals required for production deployments. Verify deployment plan and rollback procedure.'
            Ensure                = 'Present'
        }
    }
}

MultipleApprovalsRequired
Start-DscConfiguration -Path ./MultipleApprovalsRequired -Wait -Verbose
```

### Example 3: Configure Approvals for Multiple Environments

```powershell
Configuration MultiEnvironmentApprovals {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoEnvironmentApproval 'StagingApproval' {
            ProjectName           = 'MyProject'
            EnvironmentName       = 'Staging'
            Approvers             = @('staging-lead@company.com')
            RequiredApproverCount = 1
            AllowApproverToSelf   = $true
            TimeoutInMinutes      = 480
            Ensure                = 'Present'
        }
        
        AzDoEnvironmentApproval 'ProdApproval' {
            ProjectName           = 'MyProject'
            EnvironmentName       = 'Production'
            Approvers             = @(
                'release-manager@company.com',
                'ops-lead@company.com'
            )
            RequiredApproverCount = 2
            AllowApproverToSelf   = $false
            TimeoutInMinutes      = 2880
            Instructions          = 'Production deployments require two approvals'
            Ensure                = 'Present'
        }
    }
}

MultiEnvironmentApprovals
Start-DscConfiguration -Path ./MultiEnvironmentApprovals -Wait -Verbose
```

### Example 4: Query Environment Approval Configuration

```powershell
# Get the current state of environment approvals
$properties = @{
    ProjectName     = 'MyProject'
    EnvironmentName = 'Production'
}

$result = Invoke-DscResource -Name 'AzDoEnvironmentApproval' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, EnvironmentName, Approvers, RequiredApproverCount, AllowApproverToSelf
```

### Example 5: Group-Based Approvals

```powershell
Configuration GroupBasedApprovals {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoEnvironmentApproval 'ReleaseApproval' {
            ProjectName           = 'MyProject'
            EnvironmentName       = 'Production'
            Approvers             = @('Release Approvers Group')
            RequiredApproverCount = 1
            AllowApproverToSelf   = $false
            TimeoutInMinutes      = 1440
            Ensure                = 'Present'
        }
    }
}

GroupBasedApprovals
Start-DscConfiguration -Path ./GroupBasedApprovals -Wait -Verbose
```

### Example 6: Environment with Detailed Instructions

```powershell
Configuration DetailedApprovalInstructions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoEnvironmentApproval 'ProductionApproval' {
            ProjectName           = 'MyProject'
            EnvironmentName       = 'Production'
            Approvers             = @(
                'release-manager@company.com',
                'ops-lead@company.com'
            )
            RequiredApproverCount = 2
            AllowApproverToSelf   = $false
            TimeoutInMinutes      = 2880
            Instructions          = @"
Production Deployment Approval Checklist:

1. Verify all automated tests have passed
2. Confirm rollback procedure is documented
3. Verify database migration scripts (if applicable)
4. Confirm smoke tests completed in staging
5. Check all security scans passed
6. Verify performance testing completed

Contact: devops@company.com for emergency deployments
"@
            Ensure                = 'Present'
        }
    }
}

DetailedApprovalInstructions
Start-DscConfiguration -Path ./DetailedApprovalInstructions -Wait -Verbose
```

### Example 7: Remove Environment Approval

```powershell
Configuration RemoveEnvironmentApproval {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoEnvironmentApproval 'RemoveApproval' {
            ProjectName     = 'MyProject'
            EnvironmentName = 'Dev'
            Approvers       = @()
            Ensure          = 'Absent'
        }
    }
}

RemoveEnvironmentApproval
Start-DscConfiguration -Path ./RemoveEnvironmentApproval -Wait -Verbose
```

## Important Notes

### Approver Specification

- Approvers can be specified as individual user emails or group names
- Users must be members of the organization
- Groups should be project-level groups
- Multiple approvers provide more flexibility but may slow deployments

### Approval Timeout

- Timeout is specified in minutes
- Default of 43200 minutes = 30 days
- Short timeouts (e.g., 480 = 8 hours) good for time-sensitive deployments
- Long timeouts allow planners to schedule approvals in advance

### Self-Approval

- Setting `AllowApproverToSelf = $true` allows the deployer to be their own approver
- Should only be true for non-production environments
- Production environments should require separate approvers

### Best Practices

- Require multiple approvals for production environments
- Keep approval lists small and focused
- Use groups rather than individual emails for scalability
- Include clear instructions for complex deployments
- Document approval process for the team

## Troubleshooting

### Issue: "Environment Not Found"

**Cause**: The specified environment does not exist

**Solution**:
```powershell
# Create the environment first in the release pipeline
# Verify environment name matches exactly (case-sensitive)
```

### Issue: "Approver Not Found"

**Cause**: User or group does not exist in the organization

**Solution**:
- Verify user is a member of the organization
- Check group exists at project level
- Ensure email format matches organization configuration

### Issue: "Cannot Configure Approvals"

**Cause**: Insufficient permissions or pipeline issues

**Solution**:
- Verify user has environment admin permissions
- Check personal access token has "Environment" scope
- Ensure environment is properly created in release pipeline

## Related Resources

- [AzDoPipelineEnvironment](AzDoPipelineEnvironment) - Create deployment environments
- [AzDoPipeline](AzDoPipeline) - Create and manage pipelines
- [AzDoProject](AzDoProject) - Manage Azure DevOps projects
- [AzDoGroupPermission](AzDoGroupPermission) - Manage group permissions

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
