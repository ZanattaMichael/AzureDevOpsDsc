<#
.SYNOPSIS
    DSC resource for managing Azure DevOps environment Kubernetes resources.

.DESCRIPTION
    Manages a Kubernetes namespace resource registered against a pipeline environment
    (`AzDoPipelineEnvironment`). Unlike VM and deployment-group targets, a Kubernetes resource is
    fully creatable through the REST API - it addresses a namespace via a service connection
    rather than requiring an agent to register itself.

.NOTES
    Author: Michael Zanatta

    The issue that requested this resource (`ResourceName`) names the resource identity property
    `ResourceName`. That name is reserved elsewhere in this module (`Get-AzDoDeploymentGroup`/-like
    resources use it for a different purpose and the base class machinery treats it specially in
    places), so this class calls it `KubernetesResourceName` instead.

    The Kubernetes provider API (`_apis/distributedtask/environments/{id}/providers/kubernetes`)
    only supports Create, Get/List and Delete - there is no Update. Any drift, including a Tags-only
    change, is therefore resolved by deleting the existing resource and creating a new one rather
    than by patching it in place. This means:
      - The resource's id changes on every drift correction. Anything that referred to the old id
        (approvals, checks scoped to the resource) must be re-applied afterwards.
      - Tag drift is never silently ignored: Get reports it as Changed and Set recreates the
        resource with the desired tags.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as the key
    property for the resource.

.PARAMETER EnvironmentName
    The name of the pipeline environment (`AzDoPipelineEnvironment`) the resource belongs to.

.PARAMETER KubernetesResourceName
    The name of the Kubernetes resource within the environment.

.PARAMETER Namespace
    The Kubernetes namespace the resource addresses.

.PARAMETER ClusterName
    An optional display name for the cluster.

.PARAMETER ServiceConnectionName
    The name of the Kubernetes (or Azure RM) service connection used to reach the cluster. Resolved
    to `serviceEndpointId` before the API call is made.

.PARAMETER Tags
    Tags applied to the resource. Compared case-insensitively as a set.

.EXAMPLE
    AzDoEnvironmentKubernetesResource ProdCluster
    {
        ProjectName            = 'Contoso'
        EnvironmentName        = 'Production'
        KubernetesResourceName = 'prod-namespace'
        Namespace              = 'prod'
        ServiceConnectionName  = 'prod-k8s-connection'
        Tags                   = @('prod', 'primary')
        Ensure                 = 'Present'
    }
#>

[DscResource()]
class AzDoEnvironmentKubernetesResource : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$EnvironmentName

    [DscProperty(Mandatory)]
    [System.String]$KubernetesResourceName

    [DscProperty(Mandatory)]
    [System.String]$Namespace

    [DscProperty()]
    [System.String]$ClusterName

    [DscProperty(Mandatory)]
    [System.String]$ServiceConnectionName

    [DscProperty()]
    [System.String[]]$Tags

    AzDoEnvironmentKubernetesResource()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoEnvironmentKubernetesResource] Get()
    {
        return [AzDoEnvironmentKubernetesResource]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        # Set() recreates the resource wholesale (delete + create) when anything differs, so it
        # needs every property, not a subset.
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName             = $CurrentResourceObject.ProjectName
        $properties.EnvironmentName          = $CurrentResourceObject.EnvironmentName
        $properties.KubernetesResourceName   = $CurrentResourceObject.KubernetesResourceName
        $properties.Namespace                = $CurrentResourceObject.Namespace
        $properties.ClusterName              = $CurrentResourceObject.ClusterName
        $properties.ServiceConnectionName    = $CurrentResourceObject.ServiceConnectionName
        $properties.Tags                     = $CurrentResourceObject.Tags
        $properties.LookupResult             = $CurrentResourceObject.LookupResult
        $properties.Ensure                   = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoEnvironmentKubernetesResource] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
