<#
.SYNOPSIS
Retrieves the current pipeline general settings for an Azure DevOps project.

.DESCRIPTION
Fetches the project's live pipeline general settings and compares only the settings the caller actually
specified (via PSBoundParameters) against the live values, reporting drift. Unspecified settings are left
untouched.

Also reads the organization-level pipeline settings (managed by AzDoOrgPipelineSettings). When an
org-level policy forces one of these switches ON, Azure DevOps locks it in every project and rejects
or ignores a project-level PATCH turning it back off. A managed setting that is desired 'false' while
the org forces it 'true' is excluded from drift (it can never converge) and listed in LockedProperties,
with a warning naming it.

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
A hashtable to store the lookup result.

.PARAMETER Ensure
Specifies the desired state.

.OUTPUTS
System.Collections.Hashtable
#>
function Get-AzDoPipelineSettings
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)][System.String]$ProjectName,
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

    Write-Verbose "[Get-AzDoPipelineSettings] Started."

    $OrganizationName = (Get-AzDoOrganizationName)
    $settingMap       = Get-AzDoPipelineSettingsMap

    $result = @{
        Ensure            = [Ensure]::Present
        ProjectName       = $ProjectName
        propertiesChanged = @()
        LockedProperties  = @()
        status            = $null
    }

    $live = Get-DevOpsPipelineSettings -Organization $OrganizationName -ProjectName $ProjectName
    if ($null -eq $live)
    {
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = "Could not retrieve pipeline settings for project '$ProjectName'."
        return $result
    }

    $liveState = ConvertTo-AzDoPipelineSettingsLiveState -Live $live -SettingMap $settingMap
    foreach ($dscName in $settingMap.Keys) { $result[$dscName] = $liveState[$dscName] }

    # Detect settings that an organization-level policy forces on and locks, so they are never
    # compared as drift a project-level Set() cannot fix (see AzDoOrgPipelineSettings).
    $locked  = @()
    $orgLive = Get-DevOpsOrgPipelineSettings -Organization $OrganizationName
    if ($null -ne $orgLive)
    {
        $orgLiveState = ConvertTo-AzDoPipelineSettingsLiveState -Live $orgLive -SettingMap $settingMap
        $locked = @(Get-AzDoLockedPipelineSettings -OrgLiveState $orgLiveState -BoundParameters $PSBoundParameters -SettingNames @($settingMap.Keys))
        foreach ($name in $locked)
        {
            Write-Warning "[Get-AzDoPipelineSettings] '$name' is locked ON at organization level and cannot be turned off for project '$ProjectName'. Manage it with AzDoOrgPipelineSettings."
        }
    }
    else
    {
        Write-Verbose "[Get-AzDoPipelineSettings] Could not retrieve organization pipeline settings; skipping org-lock detection."
    }

    $comparable = @($settingMap.Keys | Where-Object { $locked -notcontains $_ })
    $changed    = @(Compare-AzDoPipelineSettingsDrift -LiveState $liveState -BoundParameters $PSBoundParameters -SettingNames $comparable)

    $result.LockedProperties  = $locked
    $result.propertiesChanged = $changed
    $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }

    return $result
}
