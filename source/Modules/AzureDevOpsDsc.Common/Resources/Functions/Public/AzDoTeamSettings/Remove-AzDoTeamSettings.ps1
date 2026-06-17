Function Remove-AzDoTeamSettings
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
        [Parameter()][ValidateSet('', 'asRequirements', 'asTasks', 'off')][string]$BugsBehavior,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    # Team iteration and area-path configuration cannot be deleted — it always exists for a team
    # and falls back to the project defaults. 'Ensure = Absent' is therefore a no-op for this resource.
    Write-Verbose "[Remove-AzDoTeamSettings] Team settings for '$TeamName' cannot be removed; leaving project defaults in place."
}
