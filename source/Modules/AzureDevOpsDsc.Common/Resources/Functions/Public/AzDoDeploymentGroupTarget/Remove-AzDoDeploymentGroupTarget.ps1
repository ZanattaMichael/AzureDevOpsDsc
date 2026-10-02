<#
.SYNOPSIS
Removes (de-registers) an Azure DevOps deployment group target.

.DESCRIPTION
Deletes an already-registered deployment group target. DSC may remove a registered target even
though it never registers one - see the AzDoDeploymentGroupTarget class notes.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DeploymentGroupName
The name of the deployment group the target belongs to.

.PARAMETER MachineName
The name of the machine as registered by the agent.

.PARAMETER Tags
Tags applied to the target.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoDeploymentGroupTarget -ProjectName 'Contoso' -DeploymentGroupName 'Production' -MachineName 'prod-vm-01'
#>
Function Remove-AzDoDeploymentGroupTarget
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$DeploymentGroupName,

        [Parameter(Mandatory = $true)]
        [System.String]$MachineName,

        [Parameter()]
        [System.String[]]$Tags,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoDeploymentGroupTarget] Started."

    $existing          = $LookupResult.liveCache
    $deploymentGroupId = $LookupResult.deploymentGroupId

    if ($null -eq $existing -or $null -eq $deploymentGroupId)
    {
        Write-Verbose "[Remove-AzDoDeploymentGroupTarget] No agent registered as '$MachineName'. Nothing to remove."
        return
    }

    $organization = Get-AzDoOrganizationName

    $removed = Remove-DevOpsDeploymentGroupTarget -Organization $organization -ProjectName $ProjectName -DeploymentGroupId $deploymentGroupId -TargetId $existing.id

    Remove-CacheItem -Key ('{0}\{1}\{2}' -f $ProjectName, $DeploymentGroupName, $MachineName) -Type 'LiveDeploymentGroupTargets'

    return $removed
}
