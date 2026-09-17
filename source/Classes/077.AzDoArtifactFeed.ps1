<#
.SYNOPSIS
    DSC resource for managing Azure Artifacts feeds.
.DESCRIPTION
    This resource manages Azure Artifacts feeds. A feed can be project-scoped (set ProjectName) or
    organization-scoped (omit ProjectName). Artifact feeds allow teams to share packages (NuGet,
    npm, Maven, Python, Universal Packages).

.PARAMETER FeedName
    The name of the artifact feed. This property is mandatory and is the key property for the resource.

.PARAMETER ProjectName
    The name of the Azure DevOps project. Optional — when supplied, the feed is project-scoped; when omitted, the feed is organization-scoped.

.PARAMETER Description
    An optional description for the feed.

.PARAMETER BadgesEnabled
    Whether to enable badges for the feed. Defaults to $false.

.PARAMETER UpstreamEnabled
    Whether to enable upstream sources. Defaults to $true.

.PARAMETER HideDeletedPackageVersions
    Whether package versions that have been deleted are hidden from feed listings.
    Defaults to $true.

#>

[DscResource()]
class AzDoArtifactFeed : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$FeedName

    # Optional: when supplied the feed is project-scoped; when omitted the feed is organization-scoped.
    [DscProperty()]
    [System.String]$ProjectName

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.Boolean]$BadgesEnabled = $false

    [DscProperty()]
    [System.Boolean]$HideDeletedPackageVersions = $true

    [DscProperty()]
    [System.Boolean]$UpstreamEnabled = $true

    AzDoArtifactFeed()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoArtifactFeed] Get()
    {
        return [AzDoArtifactFeed]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName                  = $CurrentResourceObject.ProjectName
        $properties.FeedName                     = $CurrentResourceObject.FeedName
        $properties.Description                  = $CurrentResourceObject.Description
        $properties.BadgesEnabled                = $CurrentResourceObject.BadgesEnabled
        $properties.HideDeletedPackageVersions   = $CurrentResourceObject.HideDeletedPackageVersions
        $properties.UpstreamEnabled              = $CurrentResourceObject.UpstreamEnabled
        $properties.LookupResult                 = $CurrentResourceObject.LookupResult
        $properties.Ensure                       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoArtifactFeed] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
