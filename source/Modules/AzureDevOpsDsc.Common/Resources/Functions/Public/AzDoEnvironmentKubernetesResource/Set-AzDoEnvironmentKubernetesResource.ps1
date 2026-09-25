<#
.SYNOPSIS
Corrects drift on an Azure DevOps environment Kubernetes resource.

.DESCRIPTION
The Kubernetes provider has no Update endpoint, so any drift - including a Tags-only change - is
corrected by deleting the existing resource and creating a new one. The resource's id changes as
a result; anything that referred to the old id (approvals, checks scoped to the resource) has to
be re-applied afterwards.

Also repeats the environment/service-connection lookup refusal that Get already decided on,
because a Get status of Error is routed to Set, not stopped, by the DSC base class.

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
Set-AzDoEnvironmentKubernetesResource -ProjectName 'Contoso' -EnvironmentName 'Production' -KubernetesResourceName 'prod-namespace' -Namespace 'prod' -ServiceConnectionName 'prod-k8s-connection' -Tags @('prod')
#>
Function Set-AzDoEnvironmentKubernetesResource
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

    Write-Verbose "[Set-AzDoEnvironmentKubernetesResource] Started."

    if ($LookupResult.reason -eq 'EnvironmentNotFound')
    {
        Write-Error "[Set-AzDoEnvironmentKubernetesResource] Environment '$EnvironmentName' was not found in project '$ProjectName'."
        return
    }

    if ($LookupResult.reason -eq 'ServiceConnectionNotFound')
    {
        Write-Error "[Set-AzDoEnvironmentKubernetesResource] Service connection '$ServiceConnectionName' was not found in project '$ProjectName'."
        return
    }

    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        Write-Error "[Set-AzDoEnvironmentKubernetesResource] Kubernetes resource '$KubernetesResourceName' was not found on environment '$EnvironmentName'."
        return
    }

    $organization = Get-AzDoOrganizationName

    Write-Verbose "[Set-AzDoEnvironmentKubernetesResource] Recreating Kubernetes resource '$KubernetesResourceName' (id '$($existing.id)') to correct drift. The resource's id will change."

    $null = Remove-DevOpsEnvironmentKubernetesResource -Organization $organization -ProjectName $ProjectName -EnvironmentId $LookupResult.environmentId -ResourceId $existing.id

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
        Write-Error "[Set-AzDoEnvironmentKubernetesResource] Deleted the old Kubernetes resource '$KubernetesResourceName' but failed to recreate it on environment '$EnvironmentName'. The environment no longer has this resource - re-run to restore it."
        return
    }

    Add-CacheItem -Key ('{0}\{1}\{2}' -f $ProjectName, $EnvironmentName, $KubernetesResourceName) -Value $created -Type 'LiveEnvironmentKubernetesResources'
    Refresh-CacheObject -CacheType 'LiveEnvironmentKubernetesResources'

    return $created
}
