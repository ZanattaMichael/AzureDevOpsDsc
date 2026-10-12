<#
.SYNOPSIS
Applies organization-level permissions when none of the managed ACEs exist yet.

.DESCRIPTION
The organization root ACL always exists, so creating permissions is the same write as updating
them. This calls Set-AzDoOrganizationPermission.

.PARAMETER GroupName
The group this configuration block is for (the resource key).

.PARAMETER Permissions
The desired ACEs.

.PARAMETER LookupResult
The lookup result from Get-AzDoOrganizationPermission.

.PARAMETER Ensure
Supplied by the DSC base class.

.PARAMETER Force
Supplied by the DSC base class.
#>
Function New-AzDoOrganizationPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoOrganizationPermission] Started."

    Set-AzDoOrganizationPermission @PSBoundParameters
}
