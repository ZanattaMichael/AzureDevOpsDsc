<#
.SYNOPSIS
Creates a Kubernetes resource on an Azure DevOps pipeline environment.

.DESCRIPTION
Registers a Kubernetes namespace resource against a pipeline environment via a service
connection. There is no Update endpoint for this provider, so drift (including a tags-only
change) is always resolved by deleting and recreating the resource - see
Set-AzDoEnvironmentKubernetesResource.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentId
The id of the pipeline environment.

.PARAMETER KubernetesResourceName
The name of the Kubernetes resource within the environment.

.PARAMETER Namespace
The Kubernetes namespace the resource addresses.

.PARAMETER ClusterName
An optional display name for the cluster.

.PARAMETER ServiceEndpointId
The id of the service connection used to reach the cluster.

.PARAMETER Tags
Tags applied to the resource.

.EXAMPLE
New-DevOpsEnvironmentKubernetesResource -Organization 'myorg' -ProjectName 'MyProject' -EnvironmentId 12 -KubernetesResourceName 'prod-namespace' -Namespace 'prod' -ServiceEndpointId $id
#>
Function New-DevOpsEnvironmentKubernetesResource
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.Int32]$EnvironmentId,

        [Parameter(Mandatory = $true)]
        [System.String]$KubernetesResourceName,

        [Parameter(Mandatory = $true)]
        [System.String]$Namespace,

        [Parameter()]
        [System.String]$ClusterName,

        [Parameter(Mandatory = $true)]
        [System.String]$ServiceEndpointId,

        [Parameter()]
        [System.String[]]$Tags,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/environments/{2}/providers/kubernetes?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $EnvironmentId, $ApiVersion

    $body = @{
        name              = $KubernetesResourceName
        namespace         = $Namespace
        serviceEndpointId = $ServiceEndpointId
        tags              = @($Tags)
    }
    if (-not [String]::IsNullOrWhiteSpace($ClusterName)) { $body.clusterName = $ClusterName }

    try
    {
        $params = @{
            Uri         = $uri
            Method      = 'POST'
            ContentType = 'application/json'
            Body        = ($body | ConvertTo-Json)
        }
        return (Invoke-AzDevOpsApiRestMethod @params)
    }
    catch
    {
        Write-Error "[New-DevOpsEnvironmentKubernetesResource] Failed to create Kubernetes resource '$KubernetesResourceName' on environment '$EnvironmentId'. Error: $_"
        return $null
    }
}
