<#
.SYNOPSIS
    DSC resource for managing Azure DevOps organization-scoped pipeline general settings.

.DESCRIPTION
    The AzDoOrgPipelineSettings resource manages the organization's pipeline general settings
    (Organization Settings -> Pipelines -> Settings page) via the Build REST API, at
    '{org}/_apis/build/generalsettings' (no project segment). It is a singleton keyed by
    OrganizationName, following the AzDoOrganizationSettings convention for organization-level
    resources.

    This resource manages the same eight switches as the project-scoped AzDoPipelineSettings (100),
    sharing their Get/compare/Set logic through private helpers rather than duplicating it. When one
    of these switches is turned on here, Azure DevOps forces it on and locks it in every project;
    AzDoPipelineSettings detects that lock and excludes the property from its own drift comparison
    instead of looping forever on state it cannot change - manage the org-wide switch here instead.

    Only the settings explicitly specified in the configuration are reconciled; unspecified settings
    are left untouched. The settings are intrinsic to the organization and cannot be removed, so
    Ensure = 'Absent' is a no-op. Test()/Set() are inherited from the AzDevOpsDscResourceBase class.

    The issue that introduced this resource (#83) also asked about three org-only switches with no
    project equivalent - disabling classic release pipeline creation, Marketplace tasks and built-in
    tasks. They are deferred: this container cannot reach a live organization to confirm which JSON
    keys the generalsettings contract actually exposes for them, and CLAUDE.md's rule for this
    resource is "do not invent keys". See docs/ResourceRoadmap.md §7 for the follow-up.

.PARAMETER OrganizationName
    The name of the Azure DevOps organization. This is the key property and is not configurable
    after initial setup.

.PARAMETER EnforceJobAuthScope
    Limit job authorization scope to the current project for non-release pipelines, organization-wide.

.PARAMETER EnforceJobAuthScopeForReleases
    Limit job authorization scope to the current project for release pipelines, organization-wide.

.PARAMETER EnforceReferencedRepoScopedToken
    Protect access to repositories in YAML pipelines, organization-wide.

.PARAMETER EnforceSettableVar
    Limit variables that can be set at queue time, organization-wide.

.PARAMETER PublishPipelineMetadata
    Publish metadata from pipelines, organization-wide.

.PARAMETER StatusBadgesArePrivate
    Disable anonymous access to status badges, organization-wide.

.PARAMETER DisableClassicPipelineCreation
    Disable creation of classic build and release pipelines, organization-wide.

.PARAMETER DisableImpliedYAMLCiTrigger
    Disable implied YAML CI triggers, organization-wide.

.EXAMPLE
    AzDoOrgPipelineSettings HardenOrgPipelines
    {
        OrganizationName        = 'MyOrganization'
        StatusBadgesArePrivate  = 'true'
        PublishPipelineMetadata = 'false'
    }
#>

[DscResource()]
class AzDoOrgPipelineSettings : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$OrganizationName

    # Each setting is a tri-state string: '' (default) means "not managed by this resource" — only
    # settings set to 'true'/'false' are compared and applied. See AzDoPipelineSettings (100) for why
    # a plain [bool] cannot express "unmanaged" here.

    [DscProperty()]
    [ValidateSet('', 'true', 'false')]
    [System.String]$EnforceJobAuthScope

    [DscProperty()]
    [ValidateSet('', 'true', 'false')]
    [System.String]$EnforceJobAuthScopeForReleases

    [DscProperty()]
    [ValidateSet('', 'true', 'false')]
    [System.String]$EnforceReferencedRepoScopedToken

    [DscProperty()]
    [ValidateSet('', 'true', 'false')]
    [System.String]$EnforceSettableVar

    [DscProperty()]
    [ValidateSet('', 'true', 'false')]
    [System.String]$PublishPipelineMetadata

    [DscProperty()]
    [ValidateSet('', 'true', 'false')]
    [System.String]$StatusBadgesArePrivate

    [DscProperty()]
    [ValidateSet('', 'true', 'false')]
    [System.String]$DisableClassicPipelineCreation

    [DscProperty()]
    [ValidateSet('', 'true', 'false')]
    [System.String]$DisableImpliedYAMLCiTrigger

    AzDoOrgPipelineSettings()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoOrgPipelineSettings] Get()
    {
        return [AzDoOrgPipelineSettings]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        # OrganizationName is the key and must be passed to Set (the base class removes any name
        # returned here from the Set parameters), so this must be empty.
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }

        $properties.OrganizationName = $CurrentResourceObject.OrganizationName
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure

        $names = @(
            'EnforceJobAuthScope', 'EnforceJobAuthScopeForReleases', 'EnforceReferencedRepoScopedToken',
            'EnforceSettableVar', 'PublishPipelineMetadata', 'StatusBadgesArePrivate',
            'DisableClassicPipelineCreation', 'DisableImpliedYAMLCiTrigger'
        )

        # Prefer the live API values carried in LookupResult so idempotency compares actual org state.
        $lr = $CurrentResourceObject.LookupResult
        foreach ($name in $names)
        {
            if ($null -ne $lr -and $lr -is [Hashtable] -and $null -ne $lr.$name)
            {
                $properties.$name = $lr.$name
            }
            else
            {
                $properties.$name = $CurrentResourceObject.$name
            }
        }

        return $properties
    }
}
