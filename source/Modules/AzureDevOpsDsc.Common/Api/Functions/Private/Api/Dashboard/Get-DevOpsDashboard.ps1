<#
.SYNOPSIS
Retrieves dashboards for a team or project.

.DESCRIPTION
Lists the dashboards on the team route, or on the project route when no team is given, and
filters client-side by name - the Dashboard API has no get-by-name lookup. On the project route
only project-scoped dashboards are considered (dashboardScope 'project', or no owning team), so a
team dashboard with the same name is never mistaken for the project one. Returns $null when Name
is supplied and nothing matches, so callers can treat "not found" as a normal Get() outcome.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TeamName
The team that owns the dashboard. Omit for a project-scoped dashboard.

.PARAMETER Name
When supplied, returns the single dashboard with this name (or $null). When omitted, returns
every dashboard in scope.

.EXAMPLE
Get-DevOpsDashboard -Organization 'myorg' -ProjectName 'MyProject' -TeamName 'MyProject Team' -Name 'Overview'
#>
Function Get-DevOpsDashboard
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

        [Parameter()]
        [String]$Name,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.3'
    )

    $uri = Get-DevOpsDashboardUri -Organization $Organization -ProjectName $ProjectName -TeamName $TeamName -ApiVersion $ApiVersion
    $scopeDescription = if ([String]::IsNullOrWhiteSpace($TeamName)) { "project '$ProjectName'" } else { "team '$TeamName' in project '$ProjectName'" }

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET'
    }
    catch
    {
        throw "[Get-DevOpsDashboard] Failed to list dashboards for $scopeDescription. Error: $_"
    }

    $dashboards = @($response.value)

    if ([String]::IsNullOrWhiteSpace($TeamName))
    {
        # The scope may be serialized as its name or its numeric value (Project = 2).
        $dashboards = @($dashboards | Where-Object {
            ([String]$_.dashboardScope -in @('project', '2')) -or [String]::IsNullOrWhiteSpace([String]$_.groupId)
        })
    }

    if ($PSBoundParameters.ContainsKey('Name') -and (-not [String]::IsNullOrWhiteSpace($Name)))
    {
        return ($dashboards | Where-Object { $_.name -eq $Name } | Select-Object -First 1)
    }

    return $dashboards
}
