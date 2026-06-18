<#
.SYNOPSIS
No-op removal for Azure DevOps pipeline general settings.

.DESCRIPTION
Pipeline general settings are intrinsic to a project and cannot be removed, so Ensure = 'Absent' is a
no-op. This function exists to satisfy the base-class dispatch and emits a warning if invoked.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnforceJobAuthScope
Limit job authorization scope to the current project for non-release pipelines.

.PARAMETER EnforceJobAuthScopeForReleases
Limit job authorization scope to the current project for release pipelines.

.PARAMETER EnforceReferencedRepoScopedToken
Protect access to repositories in YAML pipelines.

.PARAMETER EnforceSettableVar
Limit variables that can be set at queue time.

.PARAMETER PublishPipelineMetadata
Publish metadata from pipelines.

.PARAMETER StatusBadgesArePrivate
Disable anonymous access to status badges.

.PARAMETER DisableClassicPipelineCreation
Disable creation of classic build and release pipelines.

.PARAMETER DisableImpliedYAMLCiTrigger
Disable implied YAML CI triggers.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Remove-AzDoPipelineSettings
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)][System.String]$ProjectName,
        [Parameter()][System.Boolean]$EnforceJobAuthScope,
        [Parameter()][System.Boolean]$EnforceJobAuthScopeForReleases,
        [Parameter()][System.Boolean]$EnforceReferencedRepoScopedToken,
        [Parameter()][System.Boolean]$EnforceSettableVar,
        [Parameter()][System.Boolean]$PublishPipelineMetadata,
        [Parameter()][System.Boolean]$StatusBadgesArePrivate,
        [Parameter()][System.Boolean]$DisableClassicPipelineCreation,
        [Parameter()][System.Boolean]$DisableImpliedYAMLCiTrigger,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Warning "[Remove-AzDoPipelineSettings] Pipeline general settings cannot be removed; ignoring Ensure = 'Absent' for project '$ProjectName'."
}
