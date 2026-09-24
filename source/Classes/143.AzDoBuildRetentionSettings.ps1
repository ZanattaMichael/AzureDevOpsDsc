<#
.SYNOPSIS
    DSC resource for managing Azure DevOps project run and artifact retention settings.

.DESCRIPTION
    The AzDoBuildRetentionSettings resource manages a project's pipeline retention policy (the
    Project Settings -> Pipelines -> Settings -> Retention page) via the Build REST API
    (`_apis/build/retention`). Only the settings explicitly specified in the configuration are
    reconciled; unspecified settings are left untouched. Each setting is validated against the
    org's own min/max bounds, read live from the API rather than hard-coded, before it is ever
    written - a value outside those bounds is refused with no PATCH sent.

    The settings are intrinsic to a project and cannot be removed, so Ensure = 'Absent' is a no-op.
    Test()/Set() are inherited from the AzDevOpsDscResourceBase class.

    Out of scope: the classic-pipeline-era 'maximum retention policy' and 'default retention policy'
    values exposed at `_apis/build/settings` are not managed here. They only apply to the classic
    build/release pipeline experience being retired alongside classic release management (see
    issue #86), while this resource targets the current per-setting retention page that applies to
    both YAML and classic pipelines.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER DaysToKeepRuns
    The number of days to keep pipeline runs before they are purged (API field 'purgeRuns'). Rejected
    if outside the org's live min/max range for this setting.

.PARAMETER DaysToKeepArtifacts
    The number of days to keep build artifacts, symbols and attachments before they are purged (API
    field 'purgeArtifacts'). Rejected if outside the org's live min/max range for this setting.

.PARAMETER DaysToKeepPullRequestRuns
    The number of days to keep runs triggered by pull requests before they are purged (API field
    'purgePullRequestRuns'). Rejected if outside the org's live min/max range for this setting.

.PARAMETER RunsToRetainPerProtectedBranch
    The minimum number of runs to always retain per protected branch, regardless of age (API field
    'retainRunsPerProtectedBranch'). Rejected if outside the org's live min/max range for this setting.

.EXAMPLE
    AzDoBuildRetentionSettings ProjectRetention
    {
        ProjectName                    = 'MyProject'
        DaysToKeepRuns                 = 30
        DaysToKeepArtifacts            = 14
        DaysToKeepPullRequestRuns      = 10
        RunsToRetainPerProtectedBranch = 3
    }
#>

[DscResource()]
class AzDoBuildRetentionSettings : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    # Each setting is a nullable int: $null (default) means "not managed by this resource" - only
    # settings the caller actually sets are compared and applied. A plain [int] cannot express
    # "unmanaged" (it defaults to 0, a value that would then be written back on every apply), which
    # would make the resource drive every omitted setting to zero (destructive, and never
    # converging because the base class passes all properties).

    [DscProperty()]
    [Nullable[System.Int32]]$DaysToKeepRuns

    [DscProperty()]
    [Nullable[System.Int32]]$DaysToKeepArtifacts

    [DscProperty()]
    [Nullable[System.Int32]]$DaysToKeepPullRequestRuns

    [DscProperty()]
    [Nullable[System.Int32]]$RunsToRetainPerProtectedBranch

    AzDoBuildRetentionSettings()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoBuildRetentionSettings] Get()
    {
        return [AzDoBuildRetentionSettings]$($this.GetDscCurrentStateProperties())
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
            'DaysToKeepRuns', 'DaysToKeepArtifacts', 'DaysToKeepPullRequestRuns', 'RunsToRetainPerProtectedBranch'
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
