<#
.SYNOPSIS
    DSC resource for managing Azure DevOps project pipeline general settings.

.DESCRIPTION
    The AzDoPipelineSettings resource manages a project's pipeline general settings (the
    Project Settings -> Pipelines -> Settings page) via the Build REST API. Only the settings explicitly
    specified in the configuration are reconciled; unspecified settings are left untouched. The settings
    are intrinsic to a project and cannot be removed, so Ensure = 'Absent' is a no-op. Test()/Set() are
    inherited from the AzDevOpsDscResourceBase class.

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

.EXAMPLE
    AzDoPipelineSettings HardenPipelines
    {
        ProjectName                      = 'MyProject'
        EnforceJobAuthScope              = $true
        EnforceReferencedRepoScopedToken = $true
        StatusBadgesArePrivate           = $true
    }
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoPipelineSettings : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty()]
    [System.Boolean]$EnforceJobAuthScope

    [DscProperty()]
    [System.Boolean]$EnforceJobAuthScopeForReleases

    [DscProperty()]
    [System.Boolean]$EnforceReferencedRepoScopedToken

    [DscProperty()]
    [System.Boolean]$EnforceSettableVar

    [DscProperty()]
    [System.Boolean]$PublishPipelineMetadata

    [DscProperty()]
    [System.Boolean]$StatusBadgesArePrivate

    [DscProperty()]
    [System.Boolean]$DisableClassicPipelineCreation

    [DscProperty()]
    [System.Boolean]$DisableImpliedYAMLCiTrigger

    AzDoPipelineSettings()
    {
        $this.Construct()
    }

    [AzDoPipelineSettings] Get()
    {
        return [AzDoPipelineSettings]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        # ProjectName is the key and must be passed to Set (the base class removes any name returned
        # here from the Set parameters), so this must be empty.
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }

        $properties.ProjectName  = $CurrentResourceObject.ProjectName
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        $names = @(
            'EnforceJobAuthScope', 'EnforceJobAuthScopeForReleases', 'EnforceReferencedRepoScopedToken',
            'EnforceSettableVar', 'PublishPipelineMetadata', 'StatusBadgesArePrivate',
            'DisableClassicPipelineCreation', 'DisableImpliedYAMLCiTrigger'
        )

        # Prefer the live API values carried in LookupResult so idempotency compares actual project state.
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
