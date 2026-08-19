# AzDoAgentPool Resource

## Description

The `AzDoAgentPool` DSC resource is used to create and manage agent pools in Azure DevOps. Agent pools are collections of build and deployment agents that run pipeline jobs. They can be self-hosted (on-premises or cloud) or Microsoft-hosted pools, and they are essential infrastructure for CI/CD pipelines.

## Syntax

```powershell
AzDoAgentPool [string] #ResourceName
{
    PoolName = [String] $PoolName
    [ PoolType = [String] {'automation', 'deployment'} ]
    [ AutoProvision = [Boolean] $AutoProvision ]
    [ AutoUpdate = [Boolean] $AutoUpdate ]
    [ IsHosted = [Boolean] $IsHosted ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **PoolName** [String] - The name of the agent pool. Must be unique within the organization.

### Optional Properties

- **PoolType** [String] - The type of pool:
  - `'automation'` - (default) For build and CI/CD pipelines
  - `'deployment'` - For deployment and release pipelines

- **AutoProvision** [Boolean] - Whether to automatically provision agents. Default is `$false`.

- **AutoUpdate** [Boolean] - Whether to automatically update agents. Default is `$true`.

- **IsHosted** [Boolean] - Whether this is a Microsoft-hosted pool. Default is `$false`. Read-only for existing pools.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Pool should exist
  - `'Absent'` - Pool should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **PoolName** - The name of the agent pool
- **PoolType** - The type of pool ('automation' or 'deployment')
- **AutoProvision** - Whether auto provisioning is enabled
- **AutoUpdate** - Whether auto updates are enabled
- **IsHosted** - Whether it's a Microsoft-hosted pool
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create Self-Hosted Agent Pool

```powershell
Configuration CreateAgentPool {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPool 'MyAgentPool' {
            PoolName     = 'On-Prem Agents'
            PoolType     = 'automation'
            AutoProvision = $false
            AutoUpdate    = $true
            IsHosted      = $false
            Ensure        = 'Present'
        }
    }
}

CreateAgentPool
Start-DscConfiguration -Path ./CreateAgentPool -Wait -Verbose
```

### Example 2: Create Deployment Agent Pool

```powershell
Configuration CreateDeploymentPool {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPool 'DeploymentAgentPool' {
            PoolName     = 'Production Agents'
            PoolType     = 'deployment'
            AutoProvision = $false
            AutoUpdate    = $true
            IsHosted      = $false
            Ensure        = 'Present'
        }
    }
}

CreateDeploymentPool
Start-DscConfiguration -Path ./CreateDeploymentPool -Wait -Verbose
```

### Example 3: Create Multiple Agent Pools

```powershell
Configuration CreateMultipleAgentPools {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPool 'BuildPool' {
            PoolName     = 'Linux Build Agents'
            PoolType     = 'automation'
            AutoProvision = $true
            AutoUpdate    = $true
            IsHosted      = $false
            Ensure        = 'Present'
        }
        
        AzDoAgentPool 'TestPool' {
            PoolName     = 'Windows Test Agents'
            PoolType     = 'automation'
            AutoProvision = $false
            AutoUpdate    = $true
            IsHosted      = $false
            Ensure        = 'Present'
        }
        
        AzDoAgentPool 'DeployPool' {
            PoolName     = 'Production Deploy Agents'
            PoolType     = 'deployment'
            AutoProvision = $false
            AutoUpdate    = $false
            IsHosted      = $false
            Ensure        = 'Present'
        }
    }
}

CreateMultipleAgentPools
Start-DscConfiguration -Path ./CreateMultipleAgentPools -Wait -Verbose
```

### Example 4: Query Agent Pool State

```powershell
# Get the current state of an agent pool
$properties = @{
    PoolName = 'On-Prem Agents'
}

$result = Invoke-DscResource -Name 'AzDoAgentPool' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object PoolName, PoolType, AutoProvision, AutoUpdate, IsHosted, Ensure
```

### Example 5: Configure Agent Pool with Auto-Update Disabled

```powershell
Configuration DisableAutoUpdate {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPool 'ControlledUpdatePool' {
            PoolName     = 'Controlled Update Agents'
            PoolType     = 'automation'
            AutoProvision = $false
            AutoUpdate    = $false
            IsHosted      = $false
            Ensure        = 'Present'
        }
    }
}

DisableAutoUpdate
Start-DscConfiguration -Path ./DisableAutoUpdate -Wait -Verbose
```

### Example 6: Create Pool with Auto-Provisioning

```powershell
Configuration AutoProvisionPool {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPool 'CloudAgentPool' {
            PoolName     = 'Cloud-Scaled Agents'
            PoolType     = 'automation'
            AutoProvision = $true
            AutoUpdate    = $true
            IsHosted      = $false
            Ensure        = 'Present'
        }
    }
}

AutoProvisionPool
Start-DscConfiguration -Path ./AutoProvisionPool -Wait -Verbose
```

### Example 7: Remove Agent Pool

```powershell
Configuration RemoveAgentPool {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPool 'RemoveOldPool' {
            PoolName = 'Deprecated Agents'
            Ensure   = 'Absent'
        }
    }
}

RemoveAgentPool
Start-DscConfiguration -Path ./RemoveAgentPool -Wait -Verbose
```

## Important Notes

### Pool Types

- **Automation** - Used for CI/CD build and continuous integration pipelines
- **Deployment** - Used for deployment and release management pipelines
- Each project queue can be linked to a specific pool type

### Agent Registration

- Creating a pool does not automatically register agents
- Agents must be manually registered or provisioned separately
- Use Azure DevOps agent download for on-premises agents

### Best Practices

- Create separate pools for different workload types (build, test, deploy)
- Use auto-update for non-critical pools
- Disable auto-update for controlled environments
- Monitor pool capacity and agent count

### Pool Management

- Pools are organization-level resources
- Can be shared across multiple projects via queue assignments
- Deleting a pool requires reassigning all queues first

## Troubleshooting

### Issue: "Pool Already Exists"

**Cause**: A pool with the same name already exists

**Solution**:
```powershell
# Use a unique pool name
# Or update the existing pool configuration
```

### Issue: "Cannot Create Pool"

**Cause**: Insufficient permissions or invalid settings

**Solution**:
- Verify user has organization-level administrator permissions
- Check personal access token has "Agent Pools (read & manage)" scope
- Ensure pool name follows naming conventions

### Issue: "Agents Not Connecting to Pool"

**Cause**: Pool created but agents not registered

**Solution**:
- Manually register agents using agent registration scripts
- Verify agent machine can reach Azure DevOps service
- Check agent PAT has correct scopes

## Related Resources

- [AzDoAgentQueue](AzDoAgentQueue) - Create agent queues in projects
- [AzDoAgentPoolPermission](AzDoAgentPoolPermission) - Manage pool permissions
- [AzDoPipeline](AzDoPipeline) - Create pipelines that use pools

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
