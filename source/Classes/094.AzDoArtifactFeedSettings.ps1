<#
.SYNOPSIS
    DSC resource for managing the settings of an Azure Artifacts feed.
.DESCRIPTION
    Manages the configurable settings of an existing feed: its upstream sources, whether deleted
    package versions are hidden, and the artifact lifecycle (retention policy). Retention is only
    managed when 'RetentionCountLimit' is greater than zero.
.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.

.PARAMETER FeedName
    The name of the artifact feed whose settings are managed. This property is mandatory. The feed itself is managed by the AzDoArtifactFeed resource.

.PARAMETER HideDeletedPackageVersions
    Whether deleted package versions are hidden. Defaults to $true.

.PARAMETER RetentionCountLimit
    The maximum number of versions to retain per package. A value of 0 (the default) means the retention policy is not managed by this resource.

.PARAMETER DaysToKeepRecentlyDownloadedPackages
    The number of days to keep recently downloaded packages, used with the retention policy.

#>
[DscResource()]
class AzDoArtifactFeedSettings : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$FeedName
    [DscProperty()][HashTable[]]$UpstreamSources
    [DscProperty()][System.Boolean]$HideDeletedPackageVersions = $true

    # Artifact lifecycle / retention policy. A 'RetentionCountLimit' of 0 means retention is not managed.
    [DscProperty()][System.Int32]$RetentionCountLimit = 0
    [DscProperty()][System.Int32]$DaysToKeepRecentlyDownloadedPackages = 0

    AzDoArtifactFeedSettings() { $this.Construct() }
    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoArtifactFeedSettings] Get() { return [AzDoArtifactFeedSettings]$($this.GetDscCurrentStateProperties()) }
    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport() { return @() }
    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject) {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName                          = $CurrentResourceObject.ProjectName
        $properties.FeedName                             = $CurrentResourceObject.FeedName
        $properties.UpstreamSources                      = $CurrentResourceObject.UpstreamSources
        $properties.HideDeletedPackageVersions           = $CurrentResourceObject.HideDeletedPackageVersions
        $properties.RetentionCountLimit                  = $CurrentResourceObject.RetentionCountLimit
        $properties.DaysToKeepRecentlyDownloadedPackages = $CurrentResourceObject.DaysToKeepRecentlyDownloadedPackages
        $properties.LookupResult                         = $CurrentResourceObject.LookupResult
        $properties.Ensure                               = $CurrentResourceObject.Ensure
        return $properties
    }
}
