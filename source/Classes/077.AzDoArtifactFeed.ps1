<#
.SYNOPSIS
    DSC resource for managing Azure Artifacts feeds.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
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