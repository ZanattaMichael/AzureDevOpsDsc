<#
.SYNOPSIS
Builds the URI for the Azure DevOps Dashboard API.

.DESCRIPTION
Dashboards live under a project, and optionally under a team within it:
{org}/{project}[/{team}]/_apis/dashboard/dashboards[/{dashboardId}]. A dashboard created on the
team route belongs to that team; one created on the project route with dashboardScope 'project'
belongs to the project. Project and team names are escaped, since both may contain spaces.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TeamName
The team that owns the dashboard. Omit for a project-scoped dashboard.

.PARAMETER DashboardId
When supplied, addresses a single dashboard rather than the collection.

.EXAMPLE
Get-DevOpsDashboardUri -Organization 'myorg' -ProjectName 'My Project' -TeamName 'My Team' -DashboardId $id
#>
Function Get-DevOpsDashboardUri
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter()]
        [String]$TeamName,

        [Parameter()]
        [String]$DashboardId,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.3'
    )

    $scope = [System.Uri]::EscapeDataString($ProjectName)

    if (-not [String]::IsNullOrWhiteSpace($TeamName))
    {
        $scope = '{0}/{1}' -f $scope, [System.Uri]::EscapeDataString($TeamName)
    }

    $path = 'https://dev.azure.com/{0}/{1}/_apis/dashboard/dashboards' -f $Organization, $scope

    if (-not [String]::IsNullOrWhiteSpace($DashboardId))
    {
        $path = '{0}/{1}' -f $path, $DashboardId
    }

    return ('{0}?api-version={1}' -f $path, $ApiVersion)
}
