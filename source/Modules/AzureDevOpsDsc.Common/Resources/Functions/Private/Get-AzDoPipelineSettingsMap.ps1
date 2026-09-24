<#
.SYNOPSIS
Returns the map of DSC pipeline-settings property names to Build REST API field names.

.DESCRIPTION
Both AzDoPipelineSettings (project-scoped) and AzDoOrgPipelineSettings (organization-scoped) manage
the same eight switches against the same 'generalsettings' API shape - one at
'{org}/{project}/_apis/build/generalsettings', the other at '{org}/_apis/build/generalsettings'. This
map is the single source of truth for the DSC-name <-> API-name pairing so both resources' Get/Set
logic stay in lockstep instead of drifting apart as separate copies.

.OUTPUTS
System.Collections.Specialized.OrderedDictionary
#>
function Get-AzDoPipelineSettingsMap
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param ()

    return [ordered]@{
        EnforceJobAuthScope              = 'enforceJobAuthScope'
        EnforceJobAuthScopeForReleases   = 'enforceJobAuthScopeForReleases'
        EnforceReferencedRepoScopedToken = 'enforceReferencedRepoScopedToken'
        EnforceSettableVar               = 'enforceSettableVar'
        PublishPipelineMetadata          = 'publishPipelineMetadata'
        StatusBadgesArePrivate           = 'statusBadgesArePrivate'
        DisableClassicPipelineCreation   = 'disableClassicPipelineCreation'
        DisableImpliedYAMLCiTrigger      = 'disableImpliedYAMLCiTrigger'
    }
}
