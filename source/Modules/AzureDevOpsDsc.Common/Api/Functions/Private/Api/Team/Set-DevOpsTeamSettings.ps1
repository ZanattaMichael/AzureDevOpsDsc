Function Set-DevOpsTeamSettings
{
    <#
        .SYNOPSIS
            Applies the iteration and area-path configuration for an Azure DevOps team.
        .DESCRIPTION
            Resolves iteration and area paths to classification-node identifiers and applies them
            to the team via the 'teamsettings', 'teamsettings/iterations' and
            'teamsettings/teamfieldvalues' endpoints.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$TeamId,
        [Parameter()][string]$BacklogIterationPath,
        [Parameter()][string]$DefaultIterationPath,
        [Parameter()][string[]]$IterationPaths,
        [Parameter()][string]$DefaultAreaPath,
        [Parameter()][string[]]$AreaPaths,
        [Parameter()][string[]]$WorkingDays,
        [Parameter()][ValidateSet('asRequirements', 'asTasks', 'off')][string]$BugsBehavior,
        [Parameter()][string]$ApiVersion = '7.1'
    )

    $org  = $ApiUri.TrimEnd('/')
    $base = '{0}/{1}/{2}/_apis/work/teamsettings' -f $org, $ProjectId, $TeamId

    # Resolve a classification node (iteration|area) path to its node identifier.
    function Resolve-ClassificationNode
    {
        param([string]$Structure, [string]$Path)
        if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
        # Strip a leading '<Project>\' prefix so the path is relative to the node root.
        $relative = ($Path -replace '^[^\\/]+[\\/]', '') -replace '\\', '/'
        $uri = '{0}/{1}/_apis/wit/classificationnodes/{2}/{3}?api-version={4}' -f $org, $ProjectId, $Structure, $relative, $ApiVersion
        try   { return Invoke-AzDevOpsApiRestMethod -Uri $uri -Method Get }
        catch { Throw "[Set-DevOpsTeamSettings] Failed to resolve $Structure path '$Path': $_" }
    }

    try
    {
        # --- Iterations -----------------------------------------------------------------
        $settingsBody = @{}
        if ($PSBoundParameters.ContainsKey('BacklogIterationPath') -and $BacklogIterationPath)
        {
            $settingsBody.backlogIteration = (Resolve-ClassificationNode -Structure 'iterations' -Path $BacklogIterationPath).identifier
        }
        if ($PSBoundParameters.ContainsKey('DefaultIterationPath') -and $DefaultIterationPath)
        {
            $settingsBody.defaultIteration = (Resolve-ClassificationNode -Structure 'iterations' -Path $DefaultIterationPath).identifier
        }
        if ($PSBoundParameters.ContainsKey('WorkingDays'))
        {
            $settingsBody.workingDays = @($WorkingDays)
        }
        if ($PSBoundParameters.ContainsKey('BugsBehavior') -and $BugsBehavior)
        {
            $settingsBody.bugsBehavior = $BugsBehavior
        }
        if ($settingsBody.Count -gt 0 -and $PSCmdlet.ShouldProcess($TeamId, 'Update team iteration settings'))
        {
            Invoke-AzDevOpsApiRestMethod -Uri ('{0}?api-version={1}' -f $base, $ApiVersion) -Method Patch `
                -ContentType 'application/json' -Body ($settingsBody | ConvertTo-Json -Depth 5) | Out-Null
        }

        # Assign the team's iteration backlog (the iterations the team participates in).
        if ($PSBoundParameters.ContainsKey('IterationPaths') -and $IterationPaths)
        {
            foreach ($iterationPath in $IterationPaths)
            {
                $node = Resolve-ClassificationNode -Structure 'iterations' -Path $iterationPath
                if ($node -and $PSCmdlet.ShouldProcess($iterationPath, 'Assign iteration to team'))
                {
                    Invoke-AzDevOpsApiRestMethod -Uri ('{0}/iterations?api-version={1}' -f $base, $ApiVersion) -Method Post `
                        -ContentType 'application/json' -Body (@{ id = $node.identifier } | ConvertTo-Json) | Out-Null
                }
            }
        }

        # --- Area paths (team field values) --------------------------------------------
        if ($PSBoundParameters.ContainsKey('DefaultAreaPath') -or $PSBoundParameters.ContainsKey('AreaPaths'))
        {
            $values = @()
            foreach ($areaPath in @($AreaPaths)) { if ($areaPath) { $values += @{ value = $areaPath; includeChildren = $true } } }

            $defaultValue = $DefaultAreaPath
            if ([string]::IsNullOrWhiteSpace($defaultValue) -and $values.Count -gt 0) { $defaultValue = $values[0].value }
            if ($defaultValue -and -not ($values | Where-Object { $_.value -eq $defaultValue }))
            {
                $values += @{ value = $defaultValue; includeChildren = $true }
            }

            $fieldBody = @{ defaultValue = $defaultValue; values = $values }
            if ($PSCmdlet.ShouldProcess($TeamId, 'Update team area paths'))
            {
                Invoke-AzDevOpsApiRestMethod -Uri ('{0}/teamfieldvalues?api-version={1}' -f $base, $ApiVersion) -Method Patch `
                    -ContentType 'application/json' -Body ($fieldBody | ConvertTo-Json -Depth 5) | Out-Null
            }
        }
    }
    catch
    {
        Throw "[Set-DevOpsTeamSettings] Failed to apply team settings for team '$TeamId': $_"
    }

    return Get-DevOpsTeamSettings -ApiUri $ApiUri -ProjectId $ProjectId -TeamId $TeamId -ApiVersion $ApiVersion
}
