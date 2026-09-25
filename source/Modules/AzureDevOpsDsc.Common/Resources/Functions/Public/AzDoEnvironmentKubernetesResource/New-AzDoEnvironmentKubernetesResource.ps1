<#
.SYNOPSIS
Creates an Azure DevOps environment Kubernetes resource.

.DESCRIPTION
Registers a Kubernetes namespace resource against a pipeline environment, using the environment
id and service endpoint id resolved by Get-AzDoEnvironmentKubernetesResource.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentName
The name of the pipeline environment the resource belongs to.

.PARAMETER KubernetesResourceName
The name of the Kubernetes resource within the environment.

.PARAMETER Namespace
The Kubernetes namespace the resource addresses.

.PARAMETER ClusterName
An optional display name for the cluster.

.PARAMETER ServiceConnectionName
The name of the service connection used to reach the cluster.

.PARAMETER Tags
Tags applied to the resource.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoEnvironmentKubernetesResource -ProjectName 'Contoso' -EnvironmentName 'Production' -KubernetesResourceName 'prod-namespace' -Namespace 'prod' -ServiceConnectionName 'prod-k8s-connection'
#>
Function New-AzDoEnvironmentKubernetesResource
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$EnvironmentName,

        [Parameter(Mandatory = $true)]
        [System.String]$KubernetesResourceName,

        [Parameter()]
        [System.String]$Namespace,

        [Parameter()]
        [System.String]$ClusterName,

        [Parameter()]
        [System.String]$ServiceConnectionName,

        [Parameter()]
        [System.String[]]$Tags,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoEnvironmentKubernetesResource] Started."

    if ($LookupResult.reason -eq 'EnvironmentNotFound')
    {
        Write-Error "[New-AzDoEnvironmentKubernetesResource] Environment '$EnvironmentName' was not found in project '$ProjectName'."
        return
    }

    if ($LookupResult.reason -eq 'ServiceConnectionNotFound')
    {
        Write-Error "[New-AzDoEnvironmentKubernetesResource] Service connection '$ServiceConnectionName' was not found in project '$ProjectName'."
        return
    }

    $organization = Get-AzDoOrganizationName

    $params = @{
        Organization           = $organization
        ProjectName             = $ProjectName
        EnvironmentId           = $LookupResult.environmentId
        KubernetesResourceName  = $KubernetesResourceName
        Namespace               = $Namespace
        ClusterName             = $ClusterName
        ServiceEndpointId       = $LookupResult.serviceEndpointId
        Tags                    = $Tags
    }

    $created = New-DevOpsEnvironmentKubernetesResource @params

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoEnvironmentKubernetesResource] Failed to create Kubernetes resource '$KubernetesResourceName' on environment '$EnvironmentName'."
        return
    }

    Add-CacheItem -Key ('{0}\{1}\{2}' -f $ProjectName, $EnvironmentName, $KubernetesResourceName) -Value $created -Type 'LiveEnvironmentKubernetesResources'
    Refresh-CacheObject -CacheType 'LiveEnvironmentKubernetesResources'

    return $created
}
