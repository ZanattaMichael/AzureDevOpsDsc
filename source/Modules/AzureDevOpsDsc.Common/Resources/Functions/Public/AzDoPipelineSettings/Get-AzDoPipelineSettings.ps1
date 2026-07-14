<#
.SYNOPSIS
Retrieves the current pipeline general settings for an Azure DevOps project.

.DESCRIPTION
Fetches the project's live pipeline general settings and compares only the settings the caller actually
specified (via PSBoundParameters) against the live values, reporting drift. Unspecified settings are left
untouched.

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

    # Map DSC property names to the API's camelCase field names.
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

    $result = @{
        Ensure            = [Ensure]::Present
        ProjectName       = $ProjectName
        propertiesChanged = @()
        status            = $null
    }

    $live = Get-DevOpsPipelineSettings -Organization $OrganizationName -ProjectName $ProjectName
    if ($null -eq $live)
    {
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = "Could not retrieve pipeline settings for project '$ProjectName'."
        return $result
    }

    $changed = @()
    foreach ($dscName in $settingMap.Keys)
    {
        $apiName    = $settingMap[$dscName]
        $liveString = if ($dscName -eq 'DisableClassicPipelineCreation')
        {
            # 'disableClassicPipelineCreation' can't actually be set (see Set-AzDoPipelineSettings), so
            # compare against the two fields that really drive it - true only when both are true.
            if ([bool]$live.disableClassicBuildPipelineCreation -and [bool]$live.disableClassicReleasePipelineCreation) { 'true' } else { 'false' }
        }
        else
        {
            if ([bool]$live.$apiName) { 'true' } else { 'false' }
        }
        $result[$dscName] = $liveString

        # Only compare settings the caller is managing (set to 'true'/'false'); '' means unmanaged.
        $desired = [string]$PSBoundParameters[$dscName]
        if (($desired -ne '') -and ($liveString -ne $desired))
        {
            $changed += $dscName
        }
    }

    $result.propertiesChanged = $changed
    $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }

    return $result
}
