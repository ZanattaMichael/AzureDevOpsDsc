<#
.SYNOPSIS
Updates an Azure DevOps dashboard.

.DESCRIPTION
Applies the desired description and refresh interval to an existing dashboard. The API replaces
the dashboard's settings on every update, so a setting the configuration does not manage is
sent back with its live value rather than left out. Widgets are never sent, so they are kept.

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
Set-AzDoDashboard -DashboardName 'Overview' -ProjectName 'Contoso' -TeamName 'Contoso Team' -Description 'Sprint overview'
#>
Function Set-AzDoDashboard
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

    Write-Verbose "[Set-AzDoDashboard] Started."

    $organization = Get-AzDoOrganizationName
    $existing = $LookupResult.liveCache

    if ($null -eq $existing)
    {
        $existing = Get-DevOpsDashboard -Organization $organization -ProjectName $ProjectName -TeamName $TeamName -Name $DashboardName
    }

    if ($null -eq $existing)
    {
        Write-Error "[Set-AzDoDashboard] Dashboard '$DashboardName' does not exist in project '$ProjectName'."
        return
    }

    $params = @{
        Organization = $organization
        ProjectName  = $ProjectName
        TeamName     = $TeamName
        DashboardId  = $existing.id
        ETag         = $existing.eTag
        Name         = $DashboardName
        Description  = if ([String]::IsNullOrWhiteSpace($Description)) { [String]$existing.description } else { $Description }
    }

    if ($RefreshInterval -ge 0)
    {
        $params.RefreshInterval = $RefreshInterval
    }
    elseif ($null -ne $existing.refreshInterval)
    {
        $params.RefreshInterval = [Int]$existing.refreshInterval
    }

    return (Update-DevOpsDashboard @params)
}
