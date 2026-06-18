<#
.SYNOPSIS
Updates the pipeline general settings for an Azure DevOps project.

.DESCRIPTION
Builds a patch of only the settings the caller specified (via PSBoundParameters) and applies them to the
project's pipeline general settings. Unspecified settings are left untouched.

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
function Set-AzDoPipelineSettings
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

    Write-Verbose "[Set-AzDoPipelineSettings] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $settingMap = [ordered]@{
        EnforceJobAuthScope              = 'enforceJobAuthScope'
        EnforceJobAuthScopeForReleases   = 'enforceJobAuthScopeForReleases'
        EnforceReferencedRepoScopedToken = 'enforceReferencedRepoScopedToken'
        EnforceSettableVar               = 'enforceSettableVar'
        PublishPipelineMetadata          = 'publishPipelineMetadata'
        StatusBadgesArePrivate           = 'statusBadgesArePrivate'
        DisableClassicPipelineCreation   = 'disableClassicPipelineCreation'
        DisableImpliedYAMLCiTrigger      = 'disableImpliedYAMLCiTrigger'
    }

    $settings = @{}
    foreach ($dscName in $settingMap.Keys)
    {
        if ($PSBoundParameters.ContainsKey($dscName))
        {
            $settings[$settingMap[$dscName]] = [bool]$PSBoundParameters[$dscName]
        }
    }

    if ($settings.Count -eq 0)
    {
        Write-Verbose "[Set-AzDoPipelineSettings] No settings specified; nothing to update."
        return
    }

    $null = Set-DevOpsPipelineSettings -Organization $OrganizationName -ProjectName $ProjectName -Settings $settings
}
