<#
.SYNOPSIS
    DSC resource for managing a view on an Azure Artifacts feed.
.DESCRIPTION
    Manages a named view on an existing feed, including its type (e.g. 'release') and its visibility
    (e.g. 'private', 'collection', 'organization', 'aadTenant').
.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.

.PARAMETER FeedName
    The name of the artifact feed that owns the view. This property is mandatory. The feed itself is managed by the AzDoArtifactFeed resource.

.PARAMETER ViewName
    The name of the feed view. This property is mandatory.

.PARAMETER ViewType
    The type of view. Valid values are release and implicit. Defaults to release.

.PARAMETER ViewVisibility
    Who can see the view. Valid values are private, collection, organization and aadTenant. Defaults to collection.

#>
[DscResource()]
class AzDoArtifactFeedView : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$FeedName
    [DscProperty(Mandatory)][System.String]$ViewName
    [DscProperty()][ValidateSet('release', 'implicit')][System.String]$ViewType = 'release'
    [DscProperty()][ValidateSet('private', 'collection', 'organization', 'aadTenant')][System.String]$ViewVisibility = 'collection'

    AzDoArtifactFeedView() { $this.Construct() }
    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
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
