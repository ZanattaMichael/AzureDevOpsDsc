<#
.SYNOPSIS
Lists the virtual machine resources registered against an Azure DevOps pipeline environment.

.DESCRIPTION
Calls the virtual machines provider of the distributed task environments API. A VM resource only
comes to exist here once an agent has installed itself against the environment - this module has
no Create call for it, and none is added: registration is agent-install-only by design.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentId
The id of the pipeline environment.

.EXAMPLE
List-DevOpsEnvironmentVMResources -Organization 'myorg' -ProjectName 'MyProject' -EnvironmentId 12
#>
Function List-DevOpsEnvironmentVMResources
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

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/environments/{2}/providers/virtualmachines?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $EnvironmentId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsEnvironmentVMResources] Failed to list virtual machine resources for environment '$EnvironmentId'. Error: $_"
        return $null
    }
}
