# AzDoPipelineEnvironment Resource

## Description

The `AzDoPipelineEnvironment` DSC resource is used to create and manage deployment environments within an Azure DevOps project. Deployment environments represent deployment targets (such as development, staging, or production) and serve as anchors for approvals, checks, and deployment history. This resource allows you to define and enforce the desired state of these environments, which are essential components of modern CI/CD pipelines.

## Syntax

```powershell
AzDoPipelineEnvironment [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    EnvironmentName = [String] $EnvironmentName
    [ Description = [String] $Description ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project. This is the unique identifier for the project in which the environment will be created.

### Mandatory Properties

- **EnvironmentName** [String] - The name of the deployment environment. This name is used when referencing the environment in pipelines and must be unique within the project.

### Optional Properties

- **Description** [String] - A description of the deployment environment explaining its purpose, deployment targets, or any special characteristics. This helps users understand the environment's intended use. Default is empty string.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Deployment environment should exist
  - `'Absent'` - Deployment environment should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **EnvironmentName** - The name of the environment
- **Description** - The description of the environment
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create a Basic Deployment Environment

```powershell
Configuration CreateBasicEnvironment {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelineEnvironment 'DevelopmentEnv' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Development'
            Description = 'Development environment for testing new features'
            Ensure = 'Present'
        }
    }
}

CreateBasicEnvironment
Start-DscConfiguration -Path ./CreateBasicEnvironment -Wait -Verbose
```

### Example 2: Create Multiple Deployment Environments

```powershell
Configuration CreateMultipleEnvironments {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelineEnvironment 'DevelopmentEnv' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Development'
            Description = 'Development environment - low risk, quick deployments'
            Ensure = 'Present'
        }
        
        AzDoPipelineEnvironment 'StagingEnv' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Staging'
            Description = 'Staging environment - pre-production testing and validation'
            Ensure = 'Present'
            DependsOn = '[AzDoPipelineEnvironment]DevelopmentEnv'
        }
        
        AzDoPipelineEnvironment 'ProductionEnv' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Production'
            Description = 'Production environment - live customer-facing application'
            Ensure = 'Present'
            DependsOn = '[AzDoPipelineEnvironment]StagingEnv'
        }
    }
}

CreateMultipleEnvironments
Start-DscConfiguration -Path ./CreateMultipleEnvironments -Wait -Verbose
```

### Example 3: Create Environments for Multi-Region Deployment

```powershell
Configuration CreateMultiRegionEnvironments {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelineEnvironment 'ProdUSEast' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Production-US-East'
            Description = 'Production environment in US East region'
            Ensure = 'Present'
        }
        
        AzDoPipelineEnvironment 'ProdUSWest' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Production-US-West'
            Description = 'Production environment in US West region'
            Ensure = 'Present'
        }
        
        AzDoPipelineEnvironment 'ProdEurope' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Production-Europe'
            Description = 'Production environment in Europe region'
            Ensure = 'Present'
        }
        
        AzDoPipelineEnvironment 'ProdAPAC' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Production-APAC'
            Description = 'Production environment in Asia-Pacific region'
            Ensure = 'Present'
        }
    }
}

CreateMultiRegionEnvironments
Start-DscConfiguration -Path ./CreateMultiRegionEnvironments -Wait -Verbose
```

### Example 4: Create Environment with Detailed Description

```powershell
Configuration CreateDetailedEnvironment {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipelineEnvironment 'ProductionEnv' {
            ProjectName = 'MyProject'
            EnvironmentName = 'Production'
            Description = @"
Production Environment
Deployed to: Azure App Service (East US)
Approval Required: Release Manager
Compliance: HIPAA, SOC2
Monitoring: Application Insights
Incident Escalation: OnCall team in #prod-incidents
"@
            Ensure = 'Present'
        }
    }
}

CreateDetailedEnvironment
Start-DscConfiguration -Path ./CreateDetailedEnvironment -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Query and Create

```powershell
# Get current environment state
$properties = @{
    ProjectName = 'MyProject'
    EnvironmentName = 'Development'
}

$result = Invoke-DscResource -Name 'AzDoPipelineEnvironment' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, EnvironmentName, Description, Ensure

# Create a new environment
$setProperties = @{
    ProjectName = 'MyProject'
    EnvironmentName = 'Development'
    Description = 'Development environment for feature development'
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoPipelineEnvironment' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Environment Naming

- Environment names must be unique within a project
- Names are case-sensitive when referenced in pipelines
- Use clear, descriptive names that indicate the environment's purpose and tier
- Common naming patterns: Development, Staging/QA, Production or Dev, Stage, Prod

### Environment Tiers

- **Development** - Early testing, experimental features, frequent deployments
- **Staging/QA** - Pre-production validation, performance testing, compliance checks
- **Production** - Live customer-facing systems, highest stability and security requirements

### Associated Approvals and Checks

- Environments can have manual approvals configured separately
- Checks can validate conditions before allowing deployment
- Permissions control who can create/manage approvals and checks
- Use `AzDoEnvironmentApproval` to configure approval groups
- Use `AzDoCheckConfiguration` to add automated checks

### Pipeline Integration

- Pipelines deploy to environments using deployment jobs
- Multiple jobs can deploy to the same environment in parallel (if allowed)
- Environments maintain deployment history and logs
- Approval and check settings are stored with the environment

### Regional and Infrastructure Considerations

- Create separate environments for different regions if applicable
- Use resource tags to track environment purpose and tier
- Consider Kubernetes namespaces for containerized deployments
- Document infrastructure details in the description

## Troubleshooting

### Issue: "Environment Name Already Exists"

**Cause**: An environment with the same name already exists in the project.

**Solution**:
```powershell
# Use a different environment name
# Or use Ensure = 'Present' which is idempotent
# Check existing environments in Project Settings -> Environments
```

### Issue: "Cannot Create Environment Due to Permissions"

**Cause**: Authentication account lacks permission to create environments.

**Solution**:
```powershell
# Verify account has project administrator rights
# Check Azure DevOps project roles
# Ensure Personal Access Token has appropriate scopes
```

### Issue: "Environment Not Appearing in Pipeline"

**Cause**: Environment exists but is not visible in pipeline deployment jobs.

**Solution**:
```powershell
# Verify environment exists in Project Settings -> Environments
# Check that your pipeline references the environment by exact name
# Verify permissions allow your account to use the environment
# Refresh the browser or reload the pipeline editor
```

### Issue: "Cannot Delete Environment in Use"

**Cause**: Pipelines or approvals reference the environment.

**Solution**:
```powershell
# Remove references to the environment from active pipelines
# Cancel any pending deployments
# Remove approval and check configurations
# Then attempt deletion again
```

## Related Resources

- [AzDoPipelineEnvironmentApproval](AzDoEnvironmentApproval.md) - Configure approvals for environments
- [AzDoCheckConfiguration](AzDoCheckConfiguration.md) - Configure automated checks for environments
- [AzDoEnvironmentPermission](AzDoEnvironmentPermission.md) - Manage environment-level permissions
- [AzDoPipeline](AzDoPipeline.md) - Create pipelines that deploy to environments
- [AzDoProject](AzDoProject.md) - Create and manage projects

## See Also

- [Azure DevOps Deployment Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments)
- [Azure DevOps Approvals and Checks](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/approvals)
- [Azure DevOps Release Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/release)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
