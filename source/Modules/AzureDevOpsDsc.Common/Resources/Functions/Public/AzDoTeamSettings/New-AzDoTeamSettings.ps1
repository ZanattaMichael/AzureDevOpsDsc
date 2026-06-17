Function New-AzDoTeamSettings
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter()][string]$BacklogIterationPath,
        [Parameter()][string]$DefaultIterationPath,
        [Parameter()][string[]]$IterationPaths,
        [Parameter()][string]$DefaultAreaPath,
        [Parameter()][string[]]$AreaPaths,
        [Parameter()][string[]]$WorkingDays,
        [Parameter()][ValidateSet('asRequirements', 'asTasks', 'off')][string]$BugsBehavior,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoTeamSettings] Configuring settings for team '$TeamName' in project '$ProjectName'."

    # Team settings always exist for an existing team, so creation and update are the same operation.
    Set-AzDoTeamSettings @PSBoundParameters
}
