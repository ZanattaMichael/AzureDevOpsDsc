# AzDoAgentQueue Resource

## Description

The `AzDoAgentQueue` DSC resource is used to create and manage agent queues within an Azure DevOps project. Agent queues link projects to agent pools, allowing pipelines within the project to access the agents in those pools. Multiple queues can point to the same pool, and you can control authorization settings for each queue.

## Syntax

```powershell
AzDoAgentQueue [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    QueueName = [String] $QueueName
    PoolName = [String] $PoolName
    [ AuthorizeAllPipelines = [Boolean] $AuthorizeAllPipelines ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

- **QueueName** [String] - The name of the agent queue within the project.

- **PoolName** [String] - The name of the agent pool to link to this queue.

### Optional Properties

- **AuthorizeAllPipelines** [Boolean] - Whether to authorize all pipelines to use this queue. Default is `$false`. When `$false`, individual pipelines must be authorized.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Queue should exist
  - `'Absent'` - Queue should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **QueueName** - The name of the queue
- **PoolName** - The name of the linked pool
- **AuthorizeAllPipelines** - Whether all pipelines are authorized
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create Agent Queue with Pool

```powershell
Configuration CreateAgentQueue {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPool 'BuildPool' {
            PoolName = 'Build Agents'
            PoolType = 'automation'
            Ensure   = 'Present'
        }
        
        AzDoAgentQueue 'BuildQueue' {
            ProjectName           = 'MyProject'
            QueueName             = 'Build Queue'
            PoolName              = 'Build Agents'
            AuthorizeAllPipelines = $false
            Ensure                = 'Present'
            DependsOn             = '[AzDoAgentPool]BuildPool'
        }
    }
}

CreateAgentQueue
Start-DscConfiguration -Path ./CreateAgentQueue -Wait -Verbose
```

### Example 2: Create Multiple Queues for Different Workloads

```powershell
Configuration MultipleQueues {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPool 'BuildPool' {
            PoolName = 'Linux Build Agents'
            PoolType = 'automation'
            Ensure   = 'Present'
        }
        
        AzDoAgentPool 'TestPool' {
            PoolName = 'Windows Test Agents'
            PoolType = 'automation'
            Ensure   = 'Present'
        }
        
        AzDoAgentQueue 'BuildQueue' {
            ProjectName           = 'MyProject'
            QueueName             = 'Build Queue'
            PoolName              = 'Linux Build Agents'
            AuthorizeAllPipelines = $true
            Ensure                = 'Present'
            DependsOn             = '[AzDoAgentPool]BuildPool'
        }
        
        AzDoAgentQueue 'TestQueue' {
            ProjectName           = 'MyProject'
            QueueName             = 'Test Queue'
            PoolName              = 'Windows Test Agents'
            AuthorizeAllPipelines = $false
            Ensure                = 'Present'
            DependsOn             = '[AzDoAgentPool]TestPool'
        }
    }
}

MultipleQueues
Start-DscConfiguration -Path ./MultipleQueues -Wait -Verbose
```

### Example 3: Create Queue with Pipeline Authorization

```powershell
Configuration AuthorizeAllPipelines {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentQueue 'DefaultQueue' {
            ProjectName           = 'MyProject'
            QueueName             = 'Default Queue'
            PoolName              = 'Default Agents'
            AuthorizeAllPipelines = $true
            Ensure                = 'Present'
        }
    }
}

AuthorizeAllPipelines
Start-DscConfiguration -Path ./AuthorizeAllPipelines -Wait -Verbose
```

### Example 4: Query Agent Queue State

```powershell
# Get the current state of an agent queue
$properties = @{
    ProjectName = 'MyProject'
    QueueName   = 'Build Queue'
}

$result = Invoke-DscResource -Name 'AzDoAgentQueue' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, QueueName, PoolName, AuthorizeAllPipelines, Ensure
```

### Example 5: Create Project with Queues

```powershell
Configuration ProjectWithQueues {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyProject' {
            ProjectName       = 'MyProject'
            Ensure            = 'Present'
            SourceControlType = 'Git'
            ProcessTemplate   = 'Agile'
        }
        
        AzDoAgentPool 'SharedPool' {
            PoolName = 'Shared Build Agents'
            PoolType = 'automation'
            Ensure   = 'Present'
        }
        
        AzDoAgentQueue 'DefaultQueue' {
            ProjectName           = 'MyProject'
            QueueName             = 'Default'
            PoolName              = 'Shared Build Agents'
            AuthorizeAllPipelines = $false
            Ensure                = 'Present'
            DependsOn             = '[AzDoProject]MyProject', '[AzDoAgentPool]SharedPool'
        }
    }
}

ProjectWithQueues
Start-DscConfiguration -Path ./ProjectWithQueues -Wait -Verbose
```

### Example 6: Secure Queue with Limited Pipeline Access

```powershell
Configuration SecureQueue {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentQueue 'RestrictedQueue' {
            ProjectName           = 'MyProject'
            QueueName             = 'Production Deploy Queue'
            PoolName              = 'Production Agents'
            AuthorizeAllPipelines = $false
            Ensure                = 'Present'
        }
    }
}

SecureQueue
Start-DscConfiguration -Path ./SecureQueue -Wait -Verbose
```

### Example 7: Remove Agent Queue

```powershell
Configuration RemoveAgentQueue {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentQueue 'RemoveOldQueue' {
            ProjectName = 'MyProject'
            QueueName   = 'Deprecated Queue'
            PoolName    = 'Old Agents'  # Required even when removing
            Ensure      = 'Absent'
        }
    }
}

RemoveAgentQueue
Start-DscConfiguration -Path ./RemoveAgentQueue -Wait -Verbose
```

## Important Notes

### Queue vs Pool

- **Agent Pool** - Organization-level resource containing agents
- **Agent Queue** - Project-level resource linking to a pool
- One pool can be used by multiple queues across different projects

### Pipeline Authorization

- When `AuthorizeAllPipelines` is `$false`, pipelines must be individually authorized
- Authorization can be managed through the Azure DevOps UI
- Default is to require explicit authorization for security

### Best Practices

- Create separate queues for different pipeline purposes (build, test, deploy)
- Use `AuthorizeAllPipelines = $false` for production/sensitive queues
- Document queue purposes and authorization requirements
- Regularly audit queue and pipeline authorization

### Queue Management

- Queues are project-scoped; each project has its own queues
- Multiple projects can share the same agent pool via different queues
- Removing a queue does not remove the pool

## Troubleshooting

### Issue: "Pool Not Found"

**Cause**: The specified agent pool does not exist

**Solution**:
```powershell
# Create the agent pool first using AzDoAgentPool resource
# Verify pool name matches exactly
```

### Issue: "Cannot Create Queue"

**Cause**: Insufficient permissions or project not found

**Solution**:
- Verify user has project administrator permissions
- Check personal access token has correct scopes
- Ensure project exists before creating queue

### Issue: "Pipelines Cannot Access Queue"

**Cause**: Queue authorization issues or missing agents

**Solution**:
- Check AuthorizeAllPipelines setting
- Manually authorize pipelines if AuthorizeAllPipelines is false
- Verify agents are registered in the pool
- Check agent connectivity to Azure DevOps

## Related Resources

- [AzDoAgentPool](AzDoAgentPool) - Create and manage agent pools
- [AzDoAgentPoolPermission](AzDoAgentPoolPermission) - Manage pool permissions
- [AzDoPipeline](AzDoPipeline) - Create pipelines that use queues
- [AzDoProject](AzDoProject) - Manage projects

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
