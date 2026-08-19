# AzDoDeploymentGroup Resource

## Description

The `AzDoDeploymentGroup` DSC resource is used to create and manage deployment groups within an Azure DevOps project. Deployment groups represent sets of machines (targets) where applications will be deployed. They are used in release pipelines for managing deployments to multiple environments and are particularly useful for on-premises or hybrid deployment scenarios.

## Syntax

```powershell
AzDoDeploymentGroup [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    DeploymentGroupName = [String] $DeploymentGroupName
    [ Description = [String] $Description ]
    [ Tags = [String[]] $Tags ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

- **DeploymentGroupName** [String] - The name of the deployment group.

### Optional Properties

- **Description** [String] - A description of the deployment group's purpose and scope.

- **Tags** [String[]] - An array of tags to categorize or organize the deployment group (e.g., @('Production', 'Web', 'Servers')).

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Deployment group should exist
  - `'Absent'` - Deployment group should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **DeploymentGroupName** - The name of the deployment group
- **Description** - The description of the deployment group
- **Tags** - The tags associated with the deployment group
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create Basic Deployment Group

```powershell
Configuration CreateDeploymentGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoDeploymentGroup 'WebServers' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Web Servers'
            Description          = 'Target servers for web application deployment'
            Tags                 = @('Production', 'Web', 'Frontend')
            Ensure               = 'Present'
        }
    }
}

CreateDeploymentGroup
Start-DscConfiguration -Path ./CreateDeploymentGroup -Wait -Verbose
```

### Example 2: Create Multiple Deployment Groups

```powershell
Configuration MultipleDeploymentGroups {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoDeploymentGroup 'WebServers' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Web Servers'
            Description          = 'Production web application servers'
            Tags                 = @('Production', 'Web', 'Frontend')
            Ensure               = 'Present'
        }
        
        AzDoDeploymentGroup 'APIServers' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'API Servers'
            Description          = 'Production API backend servers'
            Tags                 = @('Production', 'API', 'Backend')
            Ensure               = 'Present'
        }
        
        AzDoDeploymentGroup 'DatabaseServers' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Database Servers'
            Description          = 'Production database servers'
            Tags                 = @('Production', 'Database', 'Critical')
            Ensure               = 'Present'
        }
    }
}

MultipleDeploymentGroups
Start-DscConfiguration -Path ./MultipleDeploymentGroups -Wait -Verbose
```

### Example 3: Environment-Specific Deployment Groups

```powershell
Configuration EnvironmentDeploymentGroups {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoDeploymentGroup 'DevWebServers' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Development Web Servers'
            Description          = 'Development environment web servers'
            Tags                 = @('Development', 'Web', 'Low-Priority')
            Ensure               = 'Present'
        }
        
        AzDoDeploymentGroup 'StagingWebServers' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Staging Web Servers'
            Description          = 'Staging environment web servers for testing'
            Tags                 = @('Staging', 'Web', 'Medium-Priority')
            Ensure               = 'Present'
        }
        
        AzDoDeploymentGroup 'ProductionWebServers' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Production Web Servers'
            Description          = 'Production environment web servers - critical'
            Tags                 = @('Production', 'Web', 'Critical', 'Monitored')
            Ensure               = 'Present'
        }
    }
}

EnvironmentDeploymentGroups
Start-DscConfiguration -Path ./EnvironmentDeploymentGroups -Wait -Verbose
```

### Example 4: Query Deployment Group State

```powershell
# Get the current state of a deployment group
$properties = @{
    ProjectName         = 'MyProject'
    DeploymentGroupName = 'Web Servers'
}

$result = Invoke-DscResource -Name 'AzDoDeploymentGroup' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, DeploymentGroupName, Description, Tags, Ensure
```

### Example 5: Create Deployment Groups for Multi-Tier Application

```powershell
Configuration MultiTierDeployment {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoDeploymentGroup 'LoadBalancers' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Load Balancers'
            Description          = 'Load balancer tier'
            Tags                 = @('Production', 'Networking', 'Critical')
            Ensure               = 'Present'
        }
        
        AzDoDeploymentGroup 'WebTier' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Web Tier'
            Description          = 'Web application servers'
            Tags                 = @('Production', 'Web', 'Scalable')
            Ensure               = 'Present'
        }
        
        AzDoDeploymentGroup 'AppTier' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Application Tier'
            Description          = 'Application logic servers'
            Tags                 = @('Production', 'Application', 'Scalable')
            Ensure               = 'Present'
        }
        
        AzDoDeploymentGroup 'DataTier' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Database Tier'
            Description          = 'Database servers'
            Tags                 = @('Production', 'Database', 'Critical', 'HA')
            Ensure               = 'Present'
        }
    }
}

MultiTierDeployment
Start-DscConfiguration -Path ./MultiTierDeployment -Wait -Verbose
```

### Example 6: Remove Deployment Group

```powershell
Configuration RemoveDeploymentGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoDeploymentGroup 'RemoveOldGroup' {
            ProjectName          = 'MyProject'
            DeploymentGroupName  = 'Deprecated Servers'
            Ensure               = 'Absent'
        }
    }
}

RemoveDeploymentGroup
Start-DscConfiguration -Path ./RemoveDeploymentGroup -Wait -Verbose
```

## Important Notes

### Deployment Group Purposes

- Used in release pipelines for deployment targeting
- Represent sets of machines (physical servers, VMs, cloud instances)
- Enable canary, blue-green, and rolling deployments
- Support various deployment strategies

### Agent Registration

- Creating a deployment group does not register agents
- Agents must be manually registered or deployed
- Requires deployment group agent to be installed on machines

### Tags

- Tags are used to organize and filter deployment groups
- Can represent environment, tier, location, or capabilities
- Useful for deployment strategy targeting

### Best Practices

- Create separate deployment groups for each environment
- Use meaningful names and descriptions
- Tag groups by environment, tier, and purpose
- Document deployment group configurations
- Regularly review and update deployment groups

### Deployment Strategies

- Deployment groups support various strategies
- Can deploy in waves or rings
- Enable health checks and monitoring integration

## Troubleshooting

### Issue: "Project Not Found"

**Cause**: The project does not exist

**Solution**:
```powershell
# Verify project name matches exactly
# Ensure project exists before creating deployment groups
# Use AzDoProject resource to create project first
```

### Issue: "Cannot Create Deployment Group"

**Cause**: Insufficient permissions or invalid settings

**Solution**:
- Verify user has project administrator permissions
- Check personal access token has "Release" scope
- Ensure deployment group name is unique within project

### Issue: "Deployment Group Not Visible in Pipelines"

**Cause**: Agents not registered or group not properly created

**Solution**:
- Verify deployment group was created successfully
- Register agents with the deployment group
- Check deployment group is accessible from pipeline definitions

## Related Resources

- [AzDoProject](AzDoProject) - Create and manage Azure DevOps projects
- [AzDoPipelineEnvironment](AzDoPipelineEnvironment) - Create deployment environments
- [AzDoPipeline](AzDoPipeline) - Create and manage pipelines
- [AzDoAgentPool](AzDoAgentPool) - Create agent pools

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
