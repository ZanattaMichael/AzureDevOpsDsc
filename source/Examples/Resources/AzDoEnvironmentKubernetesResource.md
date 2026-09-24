# DSC AzDoEnvironmentKubernetesResource Resource

## Syntax

```PowerShell
AzDoEnvironmentKubernetesResource [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    EnvironmentName        = [String]$EnvironmentName
    KubernetesResourceName = [String]$KubernetesResourceName
    Namespace              = [String]$Namespace
    ServiceConnectionName  = [String]$ServiceConnectionName
    [ ClusterName          = [String]$ClusterName ]
    [ Tags                 = [String[]]$Tags ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **EnvironmentName**: The name of the pipeline environment (`AzDoPipelineEnvironment`) the resource belongs to.
- **KubernetesResourceName**: The name of the Kubernetes resource within the environment. (The issue that requested this resource named this property `ResourceName`; it is exposed here as `KubernetesResourceName` because `ResourceName` is reserved elsewhere in this module.)
- **Namespace**: The Kubernetes namespace the resource addresses.
- **ClusterName**: An optional display name for the cluster.
- **ServiceConnectionName**: The name of the Kubernetes (or Azure RM) service connection used to reach the cluster. Resolved to `serviceEndpointId` before the API call is made.
- **Tags**: An array of tag strings, compared case-insensitively as a set, and only enforced when this property is specified.
- **Ensure**: Specifies whether the Kubernetes resource should exist. Valid values are `Present` and `Absent`.

## Additional Information

Unlike VM and deployment group targets, an environment Kubernetes resource is fully creatable through the REST API — it addresses a namespace via a service connection rather than requiring an agent to register itself.

The Kubernetes provider API (`_apis/distributedtask/environments/{id}/providers/kubernetes`) only supports Create, Get/List and Delete — there is no Update. Any drift, including a Tags-only change, is resolved by deleting the existing resource and creating a new one rather than by patching it in place:

- The resource's id changes on every drift correction. Anything that referred to the old id (approvals, checks scoped to the resource) must be re-applied afterwards.
- Tag drift is never silently ignored: `Get` reports it as `Changed` and `Set` recreates the resource with the desired tags.

## Examples

## Example 1: Sample Configuration using AzDoEnvironmentKubernetesResource Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoEnvironmentKubernetesResource ProdCluster {
            Ensure                 = 'Present'
            ProjectName            = 'MyProject'
            EnvironmentName        = 'Production'
            KubernetesResourceName = 'prod-namespace'
            Namespace              = 'prod'
            ServiceConnectionName  = 'prod-k8s-connection'
            Tags                   = @('prod', 'primary')
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoEnvironmentKubernetesResource
$properties = @{
    ProjectName            = 'MyProject'
    EnvironmentName        = 'Production'
    KubernetesResourceName = 'prod-namespace'
    Namespace              = 'prod'
    ServiceConnectionName  = 'prod-k8s-connection'
}

Invoke-DscResource -Name 'AzDoEnvironmentKubernetesResource' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  EnvironmentName: Production
}

resources:
- name: Production Cluster Namespace
  type: AzureDevOpsDscNative/AzDoEnvironmentKubernetesResource
  dependsOn:
    - AzureDevOpsDscNative/AzDoPipelineEnvironment/Production
    - AzureDevOpsDscNative/AzDoServiceConnection/prod-k8s-connection
  properties:
    ProjectName: $ProjectName
    EnvironmentName: $EnvironmentName
    KubernetesResourceName: prod-namespace
    Namespace: prod
    ServiceConnectionName: prod-k8s-connection
    Tags:
      - prod
      - primary
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
