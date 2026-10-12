<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps dashboard.

.DESCRIPTION
Looks the dashboard up live by listing the dashboards of the team (or the project-scoped
dashboards when no team is given) and filtering by name - the Dashboard API has no get-by-name
endpoint. Description and RefreshInterval are compared only when the configuration manages them,
so a configuration that only declares the dashboard does not report drift against settings
changed in the UI. Widgets are not compared.

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
Get-AzDoDashboard -DashboardName 'Overview' -ProjectName 'Contoso' -TeamName 'Contoso Team'
#>
Function Get-AzDoDashboard
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoDashboard] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    if ([String]::IsNullOrWhiteSpace($DashboardName))
    {
        Write-Error "[Get-AzDoDashboard] A dashboard name must be supplied."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EmptyName'
        return $result
    }

    $organization = Get-AzDoOrganizationName
    $dashboard = Get-DevOpsDashboard -Organization $organization -ProjectName $ProjectName -TeamName $TeamName -Name $DashboardName

    if ($null -eq $dashboard)
    {
        Write-Verbose "[Get-AzDoDashboard] Dashboard '$DashboardName' does not exist in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $dashboard
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    if (-not [String]::IsNullOrWhiteSpace($Description) -and ($Description -ne [String]$dashboard.description))
    {
        Write-Verbose "[Get-AzDoDashboard] Description differs for '$DashboardName'."
        $propertiesChanged += 'Description'
    }

    if (($RefreshInterval -ge 0) -and ($RefreshInterval -ne [Int]$dashboard.refreshInterval))
    {
        Write-Verbose "[Get-AzDoDashboard] RefreshInterval differs for '$DashboardName'."
        $propertiesChanged += 'RefreshInterval'
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoDashboard] Dashboard '$DashboardName' status: $($result.status)."

    return $result
}
