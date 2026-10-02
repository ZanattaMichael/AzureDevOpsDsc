<#
.SYNOPSIS
Updates the tags of a virtual machine resource on an Azure DevOps pipeline environment.

.DESCRIPTION
Patches the tags of a VM resource that an agent has already registered. There is no call here to
register the resource itself - see the module notes on AzDoEnvironmentVMResource for why.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentId
The id of the pipeline environment.

.PARAMETER ResourceId
The id of the VM resource to update.

.PARAMETER Tags
The desired tags for the resource.

.EXAMPLE
Set-DevOpsEnvironmentVMResource -Organization 'myorg' -ProjectName 'MyProject' -EnvironmentId 12 -ResourceId 3 -Tags @('prod')
#>
Function Set-DevOpsEnvironmentVMResource
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
        [System.String[]]$Tags,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/environments/{2}/providers/virtualmachines/{3}?api-version={4}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $EnvironmentId, $ResourceId, $ApiVersion

    try
    {
        $params = @{
            Uri         = $uri
            Method      = 'PATCH'
            ContentType = 'application/json'
            Body        = (@{ tags = @($Tags) } | ConvertTo-Json)
        }
        return (Invoke-AzDevOpsApiRestMethod @params)
    }
    catch
    {
        Write-Error "[Set-DevOpsEnvironmentVMResource] Failed to update tags on virtual machine resource '$ResourceId' on environment '$EnvironmentId'. Error: $_"
        return $null
    }
}
