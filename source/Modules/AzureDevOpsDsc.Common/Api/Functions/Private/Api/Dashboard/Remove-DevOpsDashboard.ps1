<#
.SYNOPSIS
Deletes a dashboard.

.DESCRIPTION
Deletes a dashboard and its widgets, addressed by id.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TeamName
The team that owns the dashboard. Omit for a project-scoped dashboard.

.PARAMETER DashboardId
The id of the dashboard to delete.

.EXAMPLE
Remove-DevOpsDashboard -Organization 'myorg' -ProjectName 'MyProject' -TeamName 'MyProject Team' -DashboardId $id
#>
Function Remove-DevOpsDashboard
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter()]
        [String]$TeamName,

        [Parameter(Mandatory = $true)]
        [String]$DashboardId,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.3'
    )

    $uri = Get-DevOpsDashboardUri -Organization $Organization -ProjectName $ProjectName -TeamName $TeamName -DashboardId $DashboardId -ApiVersion $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        throw "[Remove-DevOpsDashboard] Failed to delete dashboard id $DashboardId in project '$ProjectName'. Error: $_"
    }
}
