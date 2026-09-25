<#
.SYNOPSIS
Removes a virtual machine resource from an Azure DevOps pipeline environment.

.DESCRIPTION
Deletes (de-registers) a VM resource by id. DSC is allowed to remove a resource it did not
register, per the agent-install-only registration design of AzDoEnvironmentVMResource.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentId
The id of the pipeline environment.

.PARAMETER ResourceId
The id of the VM resource to delete.

.EXAMPLE
Remove-DevOpsEnvironmentVMResource -Organization 'myorg' -ProjectName 'MyProject' -EnvironmentId 12 -ResourceId 3
#>
Function Remove-DevOpsEnvironmentVMResource
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

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/environments/{2}/providers/virtualmachines/{3}?api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $EnvironmentId, $ResourceId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsEnvironmentVMResource] Failed to delete virtual machine resource '$ResourceId' on environment '$EnvironmentId'. Error: $_"
        return $null
    }
}
