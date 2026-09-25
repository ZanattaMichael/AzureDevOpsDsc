<#
.SYNOPSIS
Removes a Kubernetes resource from an Azure DevOps pipeline environment.

.DESCRIPTION
Deletes a Kubernetes resource by id. This is also the mechanism used to correct drift, since the
provider has no Update endpoint - Set-AzDoEnvironmentKubernetesResource deletes and recreates.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentId
The id of the pipeline environment.

.PARAMETER ResourceId
The id of the Kubernetes resource to delete.

.EXAMPLE
Remove-DevOpsEnvironmentKubernetesResource -Organization 'myorg' -ProjectName 'MyProject' -EnvironmentId 12 -ResourceId 3
#>
Function Remove-DevOpsEnvironmentKubernetesResource
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
        [System.Int32]$ResourceId,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/environments/{2}/providers/kubernetes/{3}?api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $EnvironmentId, $ResourceId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsEnvironmentKubernetesResource] Failed to delete Kubernetes resource '$ResourceId' on environment '$EnvironmentId'. Error: $_"
        return $null
    }
}
