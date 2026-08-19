# AzDoServiceConnection Resource

## Description

The `AzDoServiceConnection` DSC resource is used to create and manage service connections (service endpoints) within an Azure DevOps project. Service connections provide credentials and connection information that pipelines use to authenticate with external services such as Azure subscriptions, Docker registries, Kubernetes clusters, GitHub, and many other platforms. This resource allows you to define and enforce the desired state of these critical infrastructure components.

## Syntax

```powershell
AzDoServiceConnection [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    ConnectionName = [String] $ConnectionName
    ConnectionType = [String] $ConnectionType
    [ Description = [String] $Description ]
    [ AllowAllPipelines = [Boolean] $AllowAllPipelines ]
    [ Authorization = [Hashtable] $Authorization ]
    [ Data = [Hashtable] $Data ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project where the service connection will be created.

### Mandatory Properties

- **ConnectionName** [String] - The display name of the service connection. This name is used when referencing the connection in pipelines.

- **ConnectionType** [String] - The type of service connection (e.g., 'AzureRM', 'GitHub', 'DockerRegistry', 'Kubernetes', 'ServiceFabric', 'Npm', 'NuGet'). This property is immutable after creation.

### Optional Properties

- **Description** [String] - A description of the service connection explaining its purpose and usage. Default is empty string.

- **AllowAllPipelines** [Boolean] - If `$true`, the service connection is available to all pipelines in the project without requiring explicit authorization. Default is `$false`. When `$false`, each pipeline must be explicitly granted access.

- **Authorization** [Hashtable] - A hashtable containing authentication/credential information for the service. The structure varies by connection type:
  - For AzureRM: Contains subscription ID, tenant ID, client ID, and secret
  - For GitHub: Contains personal access token
  - For DockerRegistry: Contains username and password
  - For Kubernetes: Contains server URL, certificate authority, and token

- **Data** [Hashtable] - A hashtable containing additional connection-specific data:
  - For AzureRM: Contains subscription name, resource group, etc.
  - For Kubernetes: Contains namespace, deploy namespace
  - For other types: Type-specific configuration

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Service connection should exist
  - `'Absent'` - Service connection should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **ConnectionName** - The name of the service connection
- **ConnectionType** - The type of the service connection
- **Description** - The description of the connection
- **AllowAllPipelines** - Whether all pipelines have access
- **Authorization** - The authorization/credential information
- **Data** - Additional connection-specific data
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create an Azure Resource Manager Connection

```powershell
Configuration CreateAzureConnection {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoServiceConnection 'AzureSubConnection' {
            ProjectName = 'MyProject'
            ConnectionName = 'AzureSubscription'
            ConnectionType = 'AzureRM'
            Description = 'Connection to Azure subscription for deployment'
            AllowAllPipelines = $false
            Authorization = @{
                Scheme = 'ServicePrincipal'
                SubscriptionId = '12345678-1234-1234-1234-123456789012'
                SubscriptionName = 'My Subscription'
                TenantId = 'abcdef01-2345-6789-abcd-ef0123456789'
                ServicePrincipalId = 'service-principal-id'
                ServicePrincipalKey = 'service-principal-secret'
                Scope = '/subscriptions/12345678-1234-1234-1234-123456789012'
            }
            Data = @{
                environment = 'AzureCloud'
                credentialsType = 'serviceprincipal'
            }
            Ensure = 'Present'
        }
    }
}

CreateAzureConnection
Start-DscConfiguration -Path ./CreateAzureConnection -Wait -Verbose
```

### Example 2: Create a GitHub Connection

```powershell
Configuration CreateGitHubConnection {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoServiceConnection 'GitHubConnection' {
            ProjectName = 'MyProject'
            ConnectionName = 'GitHub'
            ConnectionType = 'GitHub'
            Description = 'Connection to GitHub repositories'
            AllowAllPipelines = $true
            Authorization = @{
                Scheme = 'PersonalAccessToken'
                AccessToken = 'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
            }
            Ensure = 'Present'
        }
    }
}

CreateGitHubConnection
Start-DscConfiguration -Path ./CreateGitHubConnection -Wait -Verbose
```

### Example 3: Create a Docker Registry Connection

```powershell
Configuration CreateDockerConnection {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoServiceConnection 'DockerRegistryConnection' {
            ProjectName = 'MyProject'
            ConnectionName = 'DockerHub'
            ConnectionType = 'DockerRegistry'
            Description = 'Connection to Docker Hub registry'
            AllowAllPipelines = $false
            Authorization = @{
                Scheme = 'UsernamePassword'
                RegistryUrl = 'https://index.docker.io/v1'
                Username = 'dockerhubusername'
                Password = 'dockerhubpassword'
            }
            Data = @{
                registrytype = 'DockerHub'
            }
            Ensure = 'Present'
        }
    }
}

CreateDockerConnection
Start-DscConfiguration -Path ./CreateDockerConnection -Wait -Verbose
```

### Example 4: Create Multiple Service Connections with Different Types

```powershell
Configuration CreateMultipleConnections {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Azure development connection
        AzDoServiceConnection 'AzureDevConnection' {
            ProjectName = 'MyProject'
            ConnectionName = 'Azure Development'
            ConnectionType = 'AzureRM'
            Description = 'Azure Dev subscription connection'
            AllowAllPipelines = $true
            Authorization = @{
                Scheme = 'ServicePrincipal'
                SubscriptionId = 'dev-subscription-id'
                TenantId = 'tenant-id'
                ServicePrincipalId = 'sp-id'
                ServicePrincipalKey = 'sp-secret'
            }
            Ensure = 'Present'
        }
        
        # Azure production connection (restricted)
        AzDoServiceConnection 'AzureProdConnection' {
            ProjectName = 'MyProject'
            ConnectionName = 'Azure Production'
            ConnectionType = 'AzureRM'
            Description = 'Azure Prod subscription connection (restricted)'
            AllowAllPipelines = $false
            Authorization = @{
                Scheme = 'ServicePrincipal'
                SubscriptionId = 'prod-subscription-id'
                TenantId = 'tenant-id'
                ServicePrincipalId = 'sp-id-prod'
                ServicePrincipalKey = 'sp-secret-prod'
            }
            Ensure = 'Present'
        }
        
        # Kubernetes connection
        AzDoServiceConnection 'KubernetesConnection' {
            ProjectName = 'MyProject'
            ConnectionName = 'Kubernetes Cluster'
            ConnectionType = 'Kubernetes'
            Description = 'Kubernetes cluster connection'
            AllowAllPipelines = $false
            Authorization = @{
                Scheme = 'Certificate'
                CertificateAuthority = 'base64-encoded-ca-cert'
                ClientCertificate = 'base64-encoded-client-cert'
                ClientKey = 'base64-encoded-client-key'
            }
            Data = @{
                kubernetesurl = 'https://kubernetes.cluster.local'
                namespace = 'default'
            }
            Ensure = 'Present'
        }
    }
}

CreateMultipleConnections
Start-DscConfiguration -Path ./CreateMultipleConnections -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Query and Update

```powershell
# Get current service connection state
$properties = @{
    ProjectName = 'MyProject'
    ConnectionName = 'AzureSubscription'
    ConnectionType = 'AzureRM'
}

$result = Invoke-DscResource -Name 'AzDoServiceConnection' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, ConnectionName, ConnectionType, Description, AllowAllPipelines

# Update service connection
$setProperties = @{
    ProjectName = 'MyProject'
    ConnectionName = 'AzureSubscription'
    ConnectionType = 'AzureRM'
    Description = 'Updated Azure connection description'
    AllowAllPipelines = $true
    Authorization = @{
        Scheme = 'ServicePrincipal'
        SubscriptionId = 'subscription-id'
        TenantId = 'tenant-id'
        ServicePrincipalId = 'sp-id'
        ServicePrincipalKey = 'sp-secret'
    }
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoServiceConnection' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Immutable Properties

- **ConnectionType** cannot be changed after creation. To change the type, you must delete and recreate the connection.

### Connection Type Reference

Common connection types and their requirements:

- **AzureRM** - Azure Resource Manager subscriptions
- **GitHub** - GitHub repositories and workflows
- **GitHubEnterprise** - GitHub Enterprise Server
- **Bitbucket** - Bitbucket repositories
- **DockerRegistry** - Docker container registries
- **Kubernetes** - Kubernetes clusters
- **ServiceFabric** - Azure Service Fabric clusters
- **Npm** - npm package registries
- **NuGet** - NuGet package feeds
- **Generic** - Generic HTTP connections

### Authorization Schemes

Different connection types use different authorization schemes:

- **ServicePrincipal** - For Azure subscriptions
- **UsernamePassword** - For registries and basic auth
- **PersonalAccessToken** - For GitHub and similar platforms
- **Certificate** - For Kubernetes and mutual TLS
- **ManagedIdentity** - For Azure with managed identity

### Security Considerations

- Store sensitive credentials securely; consider using Azure Key Vault
- Restrict access to production service connections using permissions
- Regularly rotate credentials and update connections
- Use service principals with minimal required permissions
- Enable auditing on service connection usage

### Pipeline Integration

- Pipelines reference connections by name
- When `AllowAllPipelines = $false`, each pipeline requires explicit approval
- Service connection authorization can enforce additional checks
- Pipeline security groups can restrict who can approve connections

## Troubleshooting

### Issue: "Invalid Authorization Credentials"

**Cause**: The provided credentials are incorrect or have expired.

**Solution**:
```powershell
# Verify credentials are correct
# Update Authorization hashtable with valid credentials
# Test credentials independently if possible
# Ensure service principals have not been rotated
```

### Issue: "ConnectionType Cannot Be Changed"

**Cause**: Attempting to modify the ConnectionType property.

**Solution**:
```powershell
# Delete the existing connection (Ensure = 'Absent')
# Create a new connection with the desired type
# Update any pipelines referencing the connection
```

### Issue: "Connection Fails Authentication in Pipeline"

**Cause**: Credentials are valid but the service connection cannot authenticate.

**Solution**:
```powershell
# Verify Authorization and Data properties are correct
# Check firewall and network access to external service
# Verify service principal has necessary permissions
# Check connection type documentation for required fields
```

## Related Resources

- [AzDoServiceConnectionPermission](AzDoServiceConnectionPermission) - Manage service connection permissions
- [AzDoPipeline](AzDoPipeline) - Create pipelines that use service connections
- [AzDoProject](AzDoProject) - Create and manage projects
- [AzDoVariableGroup](AzDoVariableGroup) - Store connection credentials in variable groups

## See Also

- [Azure DevOps Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
- [Azure DevOps Service Connection Security](https://docs.microsoft.com/en-us/azure/devops/pipelines/security/secure-project-settings)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
