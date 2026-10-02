<#
.SYNOPSIS
Removes an Azure DevOps environment Kubernetes resource.

.DESCRIPTION
Deletes the Kubernetes resource from its parent environment.

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
Remove-AzDoEnvironmentKubernetesResource -ProjectName 'Contoso' -EnvironmentName 'Production' -KubernetesResourceName 'prod-namespace'
#>
Function Remove-AzDoEnvironmentKubernetesResource
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

    Write-Verbose "[Remove-AzDoEnvironmentKubernetesResource] Started."

    $organization = Get-AzDoOrganizationName
    $existing     = $LookupResult.liveCache
    $environmentId = $LookupResult.environmentId

    if ($null -eq $existing -or $null -eq $environmentId)
    {
        Write-Verbose "[Remove-AzDoEnvironmentKubernetesResource] Kubernetes resource '$KubernetesResourceName' does not exist. Nothing to remove."
        return
    }

    $removed = Remove-DevOpsEnvironmentKubernetesResource -Organization $organization -ProjectName $ProjectName -EnvironmentId $environmentId -ResourceId $existing.id

    Remove-CacheItem -Key ('{0}\{1}\{2}' -f $ProjectName, $EnvironmentName, $KubernetesResourceName) -Type 'LiveEnvironmentKubernetesResources'

    return $removed
}
