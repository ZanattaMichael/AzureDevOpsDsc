<#
.SYNOPSIS
    DSC resource for managing a view on an Azure Artifacts feed.
.DESCRIPTION
    Manages a named view on an existing feed, including its type (e.g. 'release') and its visibility
    (e.g. 'private', 'collection', 'organization', 'aadTenant').
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoArtifactFeedView : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Key, Mandatory)][System.String]$FeedName
    [DscProperty(Key, Mandatory)][System.String]$ViewName
    [DscProperty()][ValidateSet('release', 'implicit')][System.String]$ViewType = 'release'
    [DscProperty()][ValidateSet('private', 'collection', 'organization', 'aadTenant')][System.String]$ViewVisibility = 'collection'

    AzDoArtifactFeedView() { $this.Construct() }
    [AzDoArtifactFeedView] Get() { return [AzDoArtifactFeedView]$($this.GetDscCurrentStateProperties()) }
    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport() { return @() }
    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject) {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName    = $CurrentResourceObject.ProjectName
        $properties.FeedName       = $CurrentResourceObject.FeedName
        $properties.ViewName       = $CurrentResourceObject.ViewName
        $properties.ViewType       = $CurrentResourceObject.ViewType
        $properties.ViewVisibility = $CurrentResourceObject.ViewVisibility
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure
        return $properties
    }
}
