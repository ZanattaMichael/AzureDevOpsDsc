<#
.SYNOPSIS
    DSC resource for managing Azure DevOps dashboards.

.DESCRIPTION
    Manages the existence, description and refresh interval of a dashboard. A dashboard belongs
    either to a team (TeamName set) or to the project itself (TeamName omitted). The widgets on
    a dashboard are not managed - they are left as they are on every update.

.NOTES
    Author: Michael Zanatta

    The dashboard name is the key, so renaming a dashboard in the configuration creates a new
    dashboard rather than renaming the existing one. It also means a configuration can declare a
    given dashboard name only once, even for different teams.

.PARAMETER DashboardName
    The name of the dashboard. Unique within its team or project.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER TeamName
    The team that owns the dashboard, for example 'Contoso Team'. Omit for a project-scoped
    dashboard.

.PARAMETER Description
    A description of the dashboard. Left unmanaged when not specified.

.PARAMETER RefreshInterval
    The automatic refresh interval in minutes; 0 turns automatic refresh off. The service decides
    which intervals it accepts - the web UI offers off and 5 minutes. Left unmanaged when not
    specified.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoDashboard SprintOverview
    {
        DashboardName   = 'Sprint Overview'
        ProjectName     = 'Contoso'
        TeamName        = 'Contoso Team'
        Description     = 'Burndown and open bugs for the current sprint'
        RefreshInterval = 5
        Ensure          = 'Present'
    }
#>

[DscResource()]
class AzDoDashboard : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$DashboardName

    [DscProperty(Mandatory)]
    [System.String]$ProjectName

    [DscProperty()]
    [System.String]$TeamName

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.Int32]$RefreshInterval = -1

    AzDoDashboard()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoDashboard] Get()
    {
        return [AzDoDashboard]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.DashboardName   = $CurrentResourceObject.DashboardName
        $properties.ProjectName     = $CurrentResourceObject.ProjectName
        $properties.TeamName        = $CurrentResourceObject.TeamName
        $properties.Description     = $CurrentResourceObject.Description
        $properties.RefreshInterval = $CurrentResourceObject.RefreshInterval
        $properties.LookupResult    = $CurrentResourceObject.LookupResult
        $properties.Ensure          = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoDashboard] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
