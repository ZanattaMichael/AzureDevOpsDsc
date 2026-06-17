<#
.SYNOPSIS
    DSC resource for managing role-based permissions on Azure Artifacts feeds.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoArtifactFeedPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$FeedName

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoArtifactFeedPermission()
    {
        $this.Construct()
    }

    [AzDoArtifactFeedPermission] Get()
    {
        return [AzDoArtifactFeedPermission]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName  = $CurrentResourceObject.ProjectName
        $properties.FeedName     = $CurrentResourceObject.FeedName
        $properties.Permissions  = $CurrentResourceObject.Permissions
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoArtifactFeedPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}