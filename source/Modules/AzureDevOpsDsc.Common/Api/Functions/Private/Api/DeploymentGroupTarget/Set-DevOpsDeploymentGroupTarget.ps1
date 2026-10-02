<#
.SYNOPSIS
Updates the tags of a deployment group target.

.DESCRIPTION
Patches the tags of a target machine that an agent has already registered. There is no call here
to register the target itself - see the module notes on AzDoDeploymentGroupTarget for why. The
PATCH targets endpoint takes an array of target updates identified by id.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DeploymentGroupId
The id of the deployment group.

.PARAMETER TargetId
The id of the target to update.

.PARAMETER Tags
The desired tags for the target.

.EXAMPLE
Set-DevOpsDeploymentGroupTarget -Organization 'myorg' -ProjectName 'MyProject' -DeploymentGroupId 4 -TargetId 7 -Tags @('web')
#>
Function Set-DevOpsDeploymentGroupTarget
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
        [System.Int32]$DeploymentGroupId,

        [Parameter(Mandatory = $true)]
        [System.Int32]$TargetId,

        [Parameter()]
        [System.String[]]$Tags,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/distributedtask/deploymentgroups/{2}/targets?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $DeploymentGroupId, $ApiVersion

    $body = @(
        @{ id = $TargetId; tags = @($Tags) }
    )

    try
    {
        $params = @{
            Uri         = $uri
            Method      = 'PATCH'
            ContentType = 'application/json'
            Body        = ($body | ConvertTo-Json)
        }
        return (Invoke-AzDevOpsApiRestMethod @params)
    }
    catch
    {
        Write-Error "[Set-DevOpsDeploymentGroupTarget] Failed to update tags on target '$TargetId' in deployment group '$DeploymentGroupId'. Error: $_"
        return $null
    }
}
