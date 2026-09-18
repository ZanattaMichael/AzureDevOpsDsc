<#
.SYNOPSIS
    DSC resource for managing role-based permissions on Azure Artifacts feeds.
.DESCRIPTION
    This resource manages role-based permissions on Azure Artifacts feeds, controlling which users
    or groups can read, publish, or administer packages. Unlike other permission resources,
    Artifact Feed permissions use a role model (Reader, Contributor, Collaborator, Administrator)
    rather than individual permission bits.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER FeedName
    The name of the artifact feed. This is a key property.

#>

[DscResource()]
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

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
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
