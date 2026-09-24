<#
.SYNOPSIS
Updates the organization-scoped pipeline general settings for an Azure DevOps organization.

.DESCRIPTION
Builds a patch of only the settings the caller specified (via PSBoundParameters) and applies them to
the organization's pipeline general settings. Unspecified settings are left untouched. Shares its
patch-building logic with the project-scoped AzDoPipelineSettings resource via the private
ConvertTo-AzDoPipelineSettingsPatch helper.

.PARAMETER OrganizationName
The name of the Azure DevOps organization.

.PARAMETER EnforceJobAuthScope
Limit job authorization scope to the current project for non-release pipelines, org-wide.

.PARAMETER EnforceJobAuthScopeForReleases
Limit job authorization scope to the current project for release pipelines, org-wide.

.PARAMETER EnforceReferencedRepoScopedToken
Protect access to repositories in YAML pipelines, org-wide.

.PARAMETER EnforceSettableVar
Limit variables that can be set at queue time, org-wide.

.PARAMETER PublishPipelineMetadata
Publish metadata from pipelines, org-wide.

.PARAMETER StatusBadgesArePrivate
Disable anonymous access to status badges, org-wide.

.PARAMETER DisableClassicPipelineCreation
Disable creation of classic build and release pipelines, org-wide.

.PARAMETER DisableImpliedYAMLCiTrigger
Disable implied YAML CI triggers, org-wide.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Set-AzDoOrgPipelineSettings
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)][System.String]$OrganizationName,
        [Parameter()][System.String]$EnforceJobAuthScope,
        [Parameter()][System.String]$EnforceJobAuthScopeForReleases,
        [Parameter()][System.String]$EnforceReferencedRepoScopedToken,
        [Parameter()][System.String]$EnforceSettableVar,
        [Parameter()][System.String]$PublishPipelineMetadata,
        [Parameter()][System.String]$StatusBadgesArePrivate,
        [Parameter()][System.String]$DisableClassicPipelineCreation,
        [Parameter()][System.String]$DisableImpliedYAMLCiTrigger,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoOrgPipelineSettings] Started."

    $OrganizationApiName = (Get-AzDoOrganizationName)
    $settingMap          = Get-AzDoPipelineSettingsMap

    $settings = ConvertTo-AzDoPipelineSettingsPatch -BoundParameters $PSBoundParameters -SettingMap $settingMap

    if ($settings.Count -eq 0)
    {
        Write-Verbose "[Set-AzDoOrgPipelineSettings] No settings specified; nothing to update."
        return
    }

    $null = Set-DevOpsOrgPipelineSettings -Organization $OrganizationApiName -Settings $settings
}
