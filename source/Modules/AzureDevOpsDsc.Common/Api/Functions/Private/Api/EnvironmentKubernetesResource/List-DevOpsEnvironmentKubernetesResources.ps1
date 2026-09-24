<#
.SYNOPSIS
Lists the Kubernetes resources registered against an Azure DevOps pipeline environment.

.DESCRIPTION
Calls the Kubernetes provider of the distributed task environments API. The provider only
supports Create, List/Get and Delete - there is no Update.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentId
The id of the pipeline environment.

.EXAMPLE
List-DevOpsEnvironmentKubernetesResources -Organization 'myorg' -ProjectName 'MyProject' -EnvironmentId 12
#>
Function List-DevOpsEnvironmentKubernetesResources
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.Int32]$EnvironmentId,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/environments/{2}/providers/kubernetes?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $EnvironmentId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsEnvironmentKubernetesResources] Failed to list Kubernetes resources for environment '$EnvironmentId'. Error: $_"
        return $null
    }
}
