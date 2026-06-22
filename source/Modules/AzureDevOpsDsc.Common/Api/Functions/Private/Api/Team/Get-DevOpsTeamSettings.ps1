Function Get-DevOpsTeamSettings
{
    <#
        .SYNOPSIS
            Retrieves the iteration and area-path configuration for an Azure DevOps team.
        .DESCRIPTION
            Combines the team's 'teamsettings' (default and backlog iteration) and
            'teamfieldvalues' (default area path and assigned area paths) into a single object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$TeamId,
        [Parameter()][string]$ApiVersion = '7.1'
    )

    $base = '{0}/{1}/{2}/_apis/work/teamsettings' -f $ApiUri.TrimEnd('/'), $ProjectId, $TeamId

    try
    {
        $settings    = Invoke-AzDevOpsApiRestMethod -Uri ('{0}?api-version={1}' -f $base, $ApiVersion) -Method Get
        $fieldValues = Invoke-AzDevOpsApiRestMethod -Uri ('{0}/teamfieldvalues?api-version={1}' -f $base, $ApiVersion) -Method Get
        $iterations  = Invoke-AzDevOpsApiRestMethod -Uri ('{0}/iterations?api-version={1}' -f $base, $ApiVersion) -Method Get
    }
    catch
    {
        Throw "[Get-DevOpsTeamSettings] Failed to retrieve team settings for team '$TeamId': $_"
    }

    return [PSCustomObject]@{
        BacklogIterationPath = $settings.backlogIteration.path
        DefaultIterationPath = $settings.defaultIteration.path
        IterationPaths       = @($iterations.value  | ForEach-Object { $_.path })
        DefaultAreaPath      = $fieldValues.defaultValue
        AreaPaths            = @($fieldValues.values | ForEach-Object { $_.value })
        WorkingDays          = @($settings.workingDays)
        BugsBehavior         = $settings.bugsBehavior
        Raw                  = [PSCustomObject]@{ Settings = $settings; FieldValues = $fieldValues; Iterations = $iterations }
    }
}
