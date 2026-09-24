<#
.SYNOPSIS
Removes (de-registers) an Azure DevOps environment virtual machine resource.

.DESCRIPTION
Deletes an already-registered VM resource. DSC may remove a registered resource even though it
never registers one - see the AzDoEnvironmentVMResource class notes.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentName
The name of the pipeline environment the resource belongs to.

.PARAMETER MachineName
The name of the machine as registered by the agent.

.PARAMETER Tags
Tags applied to the resource.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoEnvironmentVMResource -ProjectName 'Contoso' -EnvironmentName 'Production' -MachineName 'prod-vm-01'
#>
Function Remove-AzDoEnvironmentVMResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$EnvironmentName,

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

    Write-Verbose "[Remove-AzDoEnvironmentVMResource] Started."

    $existing      = $LookupResult.liveCache
    $environmentId = $LookupResult.environmentId

    if ($null -eq $existing -or $null -eq $environmentId)
    {
        Write-Verbose "[Remove-AzDoEnvironmentVMResource] No agent registered as '$MachineName'. Nothing to remove."
        return
    }

    $organization = Get-AzDoOrganizationName

    $removed = Remove-DevOpsEnvironmentVMResource -Organization $organization -ProjectName $ProjectName -EnvironmentId $environmentId -ResourceId $existing.id

    Remove-CacheItem -Key ('{0}\{1}\{2}' -f $ProjectName, $EnvironmentName, $MachineName) -Type 'LiveEnvironmentVMResources'

    return $removed
}
