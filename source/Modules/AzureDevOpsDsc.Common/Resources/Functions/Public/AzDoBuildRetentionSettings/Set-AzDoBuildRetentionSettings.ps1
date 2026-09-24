<#
.SYNOPSIS
Updates the run/artifact retention settings for an Azure DevOps project.

.DESCRIPTION
Builds a patch of only the settings the caller specified (via PSBoundParameters) and applies them to
the project's retention settings. Unspecified settings are left untouched.

A Get status of 'Error' still routes to Set (see CLAUDE.md "How Get status maps to the action taken"),
so any out-of-range value Get-AzDoBuildRetentionSettings already refused is repeated here via
'$LookupResult.rangeErrors': if it is non-empty, this function throws before building or sending any
PATCH, so an out-of-range value is never written.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DaysToKeepRuns
The number of days to keep pipeline runs before they are purged.

.PARAMETER DaysToKeepArtifacts
The number of days to keep build artifacts, symbols and attachments before they are purged.

.PARAMETER DaysToKeepPullRequestRuns
The number of days to keep runs triggered by pull requests before they are purged.

.PARAMETER RunsToRetainPerProtectedBranch
The minimum number of runs to always retain per protected branch, regardless of age.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Set-AzDoBuildRetentionSettings
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)][System.String]$ProjectName,
        [Parameter()][Nullable[System.Int32]]$DaysToKeepRuns,
        [Parameter()][Nullable[System.Int32]]$DaysToKeepArtifacts,
        [Parameter()][Nullable[System.Int32]]$DaysToKeepPullRequestRuns,
        [Parameter()][Nullable[System.Int32]]$RunsToRetainPerProtectedBranch,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoBuildRetentionSettings] Started."

    # An out-of-range value was already refused by Get; a Get status of 'Error' still routes here, so
    # repeat the refusal - never PATCH a value Get flagged as out of range.
    if ($null -ne $LookupResult -and $LookupResult.rangeErrors -and @($LookupResult.rangeErrors).Count -gt 0)
    {
        throw "[Set-AzDoBuildRetentionSettings] Refusing to update retention settings for project '$ProjectName': $(@($LookupResult.rangeErrors) -join ' ')"
    }

    $OrganizationName = (Get-AzDoOrganizationName)

    $settingMap = [ordered]@{
        DaysToKeepRuns                 = 'purgeRuns'
        DaysToKeepArtifacts            = 'purgeArtifacts'
        DaysToKeepPullRequestRuns      = 'purgePullRequestRuns'
        RunsToRetainPerProtectedBranch = 'retainRunsPerProtectedBranch'
    }

    $settings = @{}
    foreach ($dscName in $settingMap.Keys)
    {
        # Only send settings the caller is managing; $null means leave untouched.
        if (-not $PSBoundParameters.ContainsKey($dscName)) { continue }
        $desired = $PSBoundParameters[$dscName]
        if ($null -eq $desired) { continue }

        $settings[$settingMap[$dscName]] = [int]$desired
    }

    if ($settings.Count -eq 0)
    {
        Write-Verbose "[Set-AzDoBuildRetentionSettings] No settings specified; nothing to update."
        return
    }

    $null = Set-DevOpsBuildRetentionSettings -Organization $OrganizationName -ProjectName $ProjectName -Settings $settings
}
