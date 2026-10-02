<#
.SYNOPSIS
No-op removal for Azure DevOps run/artifact retention settings.

.DESCRIPTION
Retention settings are intrinsic to a project and cannot be removed, so Ensure = 'Absent' is a no-op.
This function exists to satisfy the base-class dispatch and emits a warning if invoked.

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
function Remove-AzDoBuildRetentionSettings
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

    Write-Warning "[Remove-AzDoBuildRetentionSettings] Retention settings cannot be removed; ignoring Ensure = 'Absent' for project '$ProjectName'."
}
