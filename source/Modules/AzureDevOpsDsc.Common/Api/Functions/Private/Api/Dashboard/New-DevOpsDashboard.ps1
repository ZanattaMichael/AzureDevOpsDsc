<#
.SYNOPSIS
Creates a dashboard.

.DESCRIPTION
Creates an empty dashboard on the team route, or a project-scoped dashboard on the project route
when no team is given. Widgets are not managed here.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TeamName
The team that owns the dashboard. Omit for a project-scoped dashboard.

.PARAMETER Name
The name of the dashboard to create.

.PARAMETER Description
A description of the dashboard.

.PARAMETER RefreshInterval
The automatic refresh interval in minutes. Omit to leave the service default.

.EXAMPLE
New-DevOpsDashboard -Organization 'myorg' -ProjectName 'MyProject' -TeamName 'MyProject Team' -Name 'Overview'
#>
Function New-DevOpsDashboard
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter()]
        [String]$TeamName,

        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter()]
        [String]$Description,

        [Parameter()]
        [Int]$RefreshInterval,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.3'
    )

    $uri = Get-DevOpsDashboardUri -Organization $Organization -ProjectName $ProjectName -TeamName $TeamName -ApiVersion $ApiVersion

    $body = @{
        name           = $Name
        dashboardScope = if ([String]::IsNullOrWhiteSpace($TeamName)) { 'project' } else { 'project_Team' }
    }

    if ($PSBoundParameters.ContainsKey('Description'))     { $body.description = $Description }
    if ($PSBoundParameters.ContainsKey('RefreshInterval')) { $body.refreshInterval = $RefreshInterval }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[New-DevOpsDashboard] Failed to create dashboard '$Name' in project '$ProjectName'. Error: $_"
    }
}
