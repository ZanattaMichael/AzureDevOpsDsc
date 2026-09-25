<#
.SYNOPSIS
Retrieves the current run/artifact retention settings for an Azure DevOps project.

.DESCRIPTION
Fetches the project's live retention settings and compares only the settings the caller actually
specified (via PSBoundParameters) against the live values, reporting drift. Unspecified settings are
left untouched. Each specified setting is also validated against the org's own live min/max bounds for
it; a value outside those bounds is reported as an error and never compared for drift, so it can never
be reported as 'no change needed' and skipped.

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
A hashtable to store the lookup result.

.PARAMETER Ensure
Specifies the desired state.

.OUTPUTS
System.Collections.Hashtable
#>
function Get-AzDoBuildRetentionSettings
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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

    Write-Verbose "[Get-AzDoBuildRetentionSettings] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    # Map DSC property names to the API's camelCase field names.
    $settingMap = [ordered]@{
        DaysToKeepRuns                 = 'purgeRuns'
        DaysToKeepArtifacts            = 'purgeArtifacts'
        DaysToKeepPullRequestRuns      = 'purgePullRequestRuns'
        RunsToRetainPerProtectedBranch = 'retainRunsPerProtectedBranch'
    }

    $result = @{
        Ensure            = [Ensure]::Present
        ProjectName       = $ProjectName
        propertiesChanged = @()
        status            = $null
    }

    $live = Get-DevOpsBuildRetentionSettings -Organization $OrganizationName -ProjectName $ProjectName
    if ($null -eq $live)
    {
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = "Could not retrieve retention settings for project '$ProjectName'."
        return $result
    }

    $changed     = @()
    $rangeErrors = @()

    foreach ($dscName in $settingMap.Keys)
    {
        $apiName     = $settingMap[$dscName]
        $liveSetting = $live.$apiName
        $liveValue   = [int]$liveSetting.value

        $result[$dscName] = $liveValue

        # Only compare/validate settings the caller is managing; $null means unmanaged.
        if (-not $PSBoundParameters.ContainsKey($dscName)) { continue }
        $desired = $PSBoundParameters[$dscName]
        if ($null -eq $desired) { continue }

        $min = [int]$liveSetting.min
        $max = [int]$liveSetting.max

        if ($desired -lt $min -or $desired -gt $max)
        {
            $rangeErrors += "'$dscName' value $desired is outside the allowed range $min-$max for project '$ProjectName'."
            continue
        }

        if ($liveValue -ne $desired)
        {
            $changed += $dscName
        }
    }

    if ($rangeErrors.Count -gt 0)
    {
        # A Get status of 'Error' still routes to Set (see CLAUDE.md), so carry the range errors
        # through LookupResult - Set-AzDoBuildRetentionSettings repeats this refusal before it PATCHes.
        $result.status      = [DSCGetSummaryState]::Error
        $result.reason       = $rangeErrors -join ' '
        $result.rangeErrors = $rangeErrors
    }
    else
    {
        $result.propertiesChanged = $changed
        $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }
    }

    return $result
}
