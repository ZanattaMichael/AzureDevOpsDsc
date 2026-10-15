<#
.SYNOPSIS
Creates an Azure DevOps dashboard.

.DESCRIPTION
Creates an empty dashboard owned by the team, or a project-scoped dashboard when no team is
given, with the desired description and refresh interval.

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
New-AzDoDashboard -DashboardName 'Overview' -ProjectName 'Contoso' -TeamName 'Contoso Team'
#>
Function New-AzDoDashboard
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

    Write-Verbose "[New-AzDoDashboard] Started."

    $params = @{
        Organization = Get-AzDoOrganizationName
        ProjectName  = $ProjectName
        TeamName     = $TeamName
        Name         = $DashboardName
    }

    if (-not [String]::IsNullOrWhiteSpace($Description)) { $params.Description = $Description }
    if ($RefreshInterval -ge 0)                          { $params.RefreshInterval = $RefreshInterval }

    return (New-DevOpsDashboard @params)
}
