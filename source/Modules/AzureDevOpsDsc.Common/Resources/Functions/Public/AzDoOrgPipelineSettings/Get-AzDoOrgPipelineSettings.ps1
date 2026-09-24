<#
.SYNOPSIS
Retrieves the current organization-scoped pipeline general settings for an Azure DevOps organization.

.DESCRIPTION
Fetches the organization's live pipeline general settings (Organization Settings -> Pipelines ->
Settings) and compares only the settings the caller actually specified (via PSBoundParameters)
against the live values, reporting drift. Unspecified settings are left untouched. Shares its
DSC-name/API-name map and comparison logic with the project-scoped AzDoPipelineSettings resource via
private helpers (Get-AzDoPipelineSettingsMap, ConvertTo-AzDoPipelineSettingsLiveState,
Compare-AzDoPipelineSettingsDrift) so the two resources cannot drift apart.

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
A hashtable to store the lookup result.

.PARAMETER Ensure
Specifies the desired state.

.OUTPUTS
System.Collections.Hashtable
#>
function Get-AzDoOrgPipelineSettings
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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

    Write-Verbose "[Get-AzDoOrgPipelineSettings] Started."

    $settingMap = Get-AzDoPipelineSettingsMap

    $result = @{
        Ensure            = [Ensure]::Present
        OrganizationName  = $OrganizationName
        propertiesChanged = @()
        status            = $null
    }

    $live = Get-DevOpsOrgPipelineSettings -Organization (Get-AzDoOrganizationName)
    if ($null -eq $live)
    {
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = "Could not retrieve organization pipeline settings for '$OrganizationName'."
        return $result
    }

    $liveState = ConvertTo-AzDoPipelineSettingsLiveState -Live $live -SettingMap $settingMap
    foreach ($dscName in $settingMap.Keys) { $result[$dscName] = $liveState[$dscName] }

    $changed = @(Compare-AzDoPipelineSettingsDrift -LiveState $liveState -BoundParameters $PSBoundParameters -SettingNames @($settingMap.Keys))

    $result.propertiesChanged = $changed
    $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }

    return $result
}
