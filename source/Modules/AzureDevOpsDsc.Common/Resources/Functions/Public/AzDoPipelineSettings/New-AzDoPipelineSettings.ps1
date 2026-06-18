<#
.SYNOPSIS
Applies pipeline general settings for an Azure DevOps project.

.DESCRIPTION
Pipeline general settings always exist for a project, so there is nothing to "create". This function
delegates to Set-AzDoPipelineSettings so the base-class dispatch behaves correctly if ever invoked.

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
function New-AzDoPipelineSettings
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

    Write-Verbose "[New-AzDoPipelineSettings] Delegating to Set-AzDoPipelineSettings."
    Set-AzDoPipelineSettings @PSBoundParameters
}
