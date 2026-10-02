<#
.SYNOPSIS
Lists the Kubernetes resources registered against an Azure DevOps pipeline environment.

.DESCRIPTION
The Kubernetes provider of the distributed task environments API has Add, Get (by id) and Delete
operations only - it has no list operation and no Update. A GET on the provider without an id does
not list anything, so the resources are found through the environment instead: the environment is
read with 'expands=resourceReferences', its references of type 'kubernetes' are selected, and each
one is then read from the provider by id so the caller gets the namespace, cluster name and service
endpoint that the reference alone does not carry.

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

    $baseUri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/environments/{2}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $EnvironmentId

    try
    {
        $environment = Invoke-AzDevOpsApiRestMethod -Uri ('{0}?expands=resourceReferences&api-version={1}' -f $baseUri, $ApiVersion) -Method 'GET'

        # EnvironmentResourceType serializes as a name; 4 is its numeric value, accepted in case a
        # caller or older server returns the number.
        $references = @($environment.resources | Where-Object { "$($_.type)" -in @('kubernetes', '4') })

        $resources = foreach ($reference in $references)
        {
            Invoke-AzDevOpsApiRestMethod -Uri ('{0}/providers/kubernetes/{1}?api-version={2}' -f $baseUri, $reference.id, $ApiVersion) -Method 'GET'
        }

        return $resources
    }
    catch
    {
        Write-Error "[List-DevOpsEnvironmentKubernetesResources] Failed to list Kubernetes resources for environment '$EnvironmentId'. Error: $_"
        return $null
    }
}
