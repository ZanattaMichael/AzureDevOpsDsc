<#
.SYNOPSIS
Updates a dashboard.

.DESCRIPTION
Replaces a dashboard's configuration with PUT, addressed by id. The API rejects a PUT without
the dashboard's current eTag (edit collision detection), and replaces the widget list only when
'widgets' is in the body - it is never sent here, so the widgets on the dashboard are left alone.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TeamName
The team that owns the dashboard. Omit for a project-scoped dashboard.

.PARAMETER DashboardId
The id of the dashboard to update.

.PARAMETER ETag
The dashboard's current eTag, as last read from the API.

.PARAMETER Name
The dashboard's name. Required on every PUT.

.PARAMETER Description
A new description.

.PARAMETER RefreshInterval
A new automatic refresh interval in minutes.

.EXAMPLE
Update-DevOpsDashboard -Organization 'myorg' -ProjectName 'MyProject' -DashboardId $id -ETag $eTag -Name 'Overview' -Description 'Team overview'
#>
Function Update-DevOpsDashboard
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
        [String]$DashboardId,

        [Parameter(Mandatory = $true)]
        [String]$ETag,

        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter()]
        [String]$Description,

        [Parameter()]
        [Int]$RefreshInterval,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.3'
    )

    $uri = Get-DevOpsDashboardUri -Organization $Organization -ProjectName $ProjectName -TeamName $TeamName -DashboardId $DashboardId -ApiVersion $ApiVersion

    $body = @{
        id   = $DashboardId
        eTag = $ETag
        name = $Name
    }

    if ($PSBoundParameters.ContainsKey('Description'))     { $body.description = $Description }
    if ($PSBoundParameters.ContainsKey('RefreshInterval')) { $body.refreshInterval = $RefreshInterval }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PUT' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[Update-DevOpsDashboard] Failed to update dashboard '$Name' (id $DashboardId) in project '$ProjectName'. Error: $_"
    }
}
