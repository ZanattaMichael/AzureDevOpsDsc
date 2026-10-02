<#
.SYNOPSIS
Applies run/artifact retention settings for an Azure DevOps project.

.DESCRIPTION
Retention settings always exist for a project, so there is nothing to "create". This function
delegates to Set-AzDoBuildRetentionSettings so the base-class dispatch behaves correctly if ever
invoked.

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
function New-AzDoBuildRetentionSettings
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

    Write-Verbose "[New-AzDoBuildRetentionSettings] Delegating to Set-AzDoBuildRetentionSettings."
    Set-AzDoBuildRetentionSettings @PSBoundParameters
}
