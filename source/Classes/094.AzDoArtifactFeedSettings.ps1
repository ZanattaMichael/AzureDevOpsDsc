<#
.SYNOPSIS
    DSC resource for managing the settings of an Azure Artifacts feed.
.DESCRIPTION
    Manages the configurable settings of an existing feed: its upstream sources, whether deleted
    package versions are hidden, and the artifact lifecycle (retention policy). Retention is only
    managed when 'RetentionCountLimit' is greater than zero.
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoArtifactFeedSettings : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Key, Mandatory)][System.String]$FeedName
    [DscProperty()][System.String[]]$UpstreamSources
    [DscProperty()][System.Boolean]$HideDeletedPackageVersions = $true

    # Artifact lifecycle / retention policy. A 'RetentionCountLimit' of 0 means retention is not managed.
    [DscProperty()][System.Int32]$RetentionCountLimit = 0
    [DscProperty()][System.Int32]$DaysToKeepRecentlyDownloadedPackages = 0

    AzDoArtifactFeedSettings() { $this.Construct() }
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
