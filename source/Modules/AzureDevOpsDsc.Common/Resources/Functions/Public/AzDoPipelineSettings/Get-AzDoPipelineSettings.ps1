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
        $apiName   = $settingMap[$dscName]
        $liveValue = [bool]$live.$apiName
        $result[$dscName] = $liveValue

        if ($PSBoundParameters.ContainsKey($dscName) -and ($liveValue -ne $PSBoundParameters[$dscName]))
        {
            $changed += $dscName
        }
    }

    $result.propertiesChanged = $changed
    $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }

    return $result
}
