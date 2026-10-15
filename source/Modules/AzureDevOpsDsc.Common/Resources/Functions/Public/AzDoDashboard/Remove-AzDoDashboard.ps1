<#
.SYNOPSIS
Removes an Azure DevOps dashboard.

.DESCRIPTION
Deletes the dashboard and the widgets on it. Removing a dashboard that does not exist is a no-op.

.PARAMETER DashboardName
The name of the dashboard.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TeamName
The team that owns the dashboard. Omit for a project-scoped dashboard.

.PARAMETER Description
The desired description. Left unmanaged when empty.

.PARAMETER RefreshInterval
The desired automatic refresh interval in minutes. Left unmanaged when negative (the default).

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoDashboard -DashboardName 'Overview' -ProjectName 'Contoso' -TeamName 'Contoso Team'
#>
Function Remove-AzDoDashboard
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$DashboardName,

        [Parameter(Mandatory = $true)]
        [System.String]$ProjectName,

        [Parameter()]
        [System.String]$TeamName,

        [Parameter()]
        [System.String]$Description,

        [Parameter()]
        [System.Int32]$RefreshInterval = -1,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoDashboard] Started."

    $organization = Get-AzDoOrganizationName
    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        $existing = Get-DevOpsDashboard -Organization $organization -ProjectName $ProjectName -TeamName $TeamName -Name $DashboardName
    }

    if ($null -eq $existing)
    {
        Write-Verbose "[Remove-AzDoDashboard] Dashboard '$DashboardName' does not exist. Nothing to remove."
        return
    }

    return (Remove-DevOpsDashboard -Organization $organization -ProjectName $ProjectName -TeamName $TeamName -DashboardId $existing.id)
}
