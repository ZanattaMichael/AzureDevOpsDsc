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
        # Only send settings the caller is managing (set to 'true'/'false'); '' means leave untouched.
        $desired = [string]$PSBoundParameters[$dscName]
        if ($desired -ne '')
        {
            $boolValue = ($desired -eq 'true')
            if ($dscName -eq 'DisableClassicPipelineCreation')
            {
                # The API's own 'disableClassicPipelineCreation' field is a read-only aggregate: PATCHing
                # it returns 200 OK but the live value never changes (a known platform bug - see
                # https://github.com/microsoft/azure-devops-go-api/issues/133). The two fields it
                # aggregates ARE independently settable, so drive those instead.
                $settings['disableClassicBuildPipelineCreation']   = $boolValue
                $settings['disableClassicReleasePipelineCreation'] = $boolValue
            }
            else
            {
                $settings[$settingMap[$dscName]] = $boolValue
            }
        }
    }

    if ($settings.Count -eq 0)
    {
        Write-Verbose "[Set-AzDoPipelineSettings] No settings specified; nothing to update."
        return
    }

    $null = Set-DevOpsPipelineSettings -Organization $OrganizationName -ProjectName $ProjectName -Settings $settings
}
