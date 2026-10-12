<#
.SYNOPSIS
Applies task group permissions when none of the managed ACEs exist yet.

.DESCRIPTION
Creating an ACL is the same write as updating one, so this calls Set-AzDoTaskGroupPermission. Get
also reports NotFound for a missing project or task group; Set refuses to write in that case.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TaskGroupName
The name of the task group. Omit to target the project level.

.PARAMETER isInherited
Whether the ACL inherits permissions from the project level.

.PARAMETER Permissions
The desired ACEs.

.PARAMETER LookupResult
The lookup result from Get-AzDoTaskGroupPermission.

.PARAMETER Ensure
Supplied by the DSC base class.

.PARAMETER Force
Supplied by the DSC base class.
#>
Function New-AzDoTaskGroupPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter()][string]$TaskGroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoTaskGroupPermission] Started."

    Set-AzDoTaskGroupPermission @PSBoundParameters
}
