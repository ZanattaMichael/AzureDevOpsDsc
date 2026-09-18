<#
.SYNOPSIS
    DSC resource for managing Azure DevOps project and code wikis.
.DESCRIPTION
    This resource manages wikis in Azure DevOps projects. Project wikis are automatically created
    within the project, while code wikis are sourced from content stored in a Git repository.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER WikiName
    The name of the wiki. This is a key property.

.PARAMETER WikiType
    The type of wiki. Valid values are projectWiki (a built-in project wiki) and codeWiki (a wiki sourced from a Git repository). Defaults to projectWiki.

.PARAMETER RepositoryName
    For codeWiki type, the name of the repository that contains the wiki content. Optional.

.PARAMETER MappedPath
    For codeWiki type, the folder path within the repository that contains the wiki content. Defaults to /.

.PARAMETER Version
    For codeWiki type, the branch or commit to use. Optional.

#>

[DscResource()]
class AzDoWiki : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$WikiName

    [DscProperty()]
    [ValidateSet('projectWiki','codeWiki')]
    [System.String]$WikiType = 'projectWiki'

    [DscProperty()]
    [System.String]$RepositoryName

    [DscProperty()]
    [System.String]$MappedPath = '/'

    [DscProperty()]
    [System.String]$Version

    AzDoWiki()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoWiki] Get()
    {
        return [AzDoWiki]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName    = $CurrentResourceObject.ProjectName
        $properties.WikiName       = $CurrentResourceObject.WikiName
        $properties.WikiType       = $CurrentResourceObject.WikiType
        $properties.RepositoryName = $CurrentResourceObject.RepositoryName
        $properties.MappedPath     = $CurrentResourceObject.MappedPath
        $properties.Version        = $CurrentResourceObject.Version
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure
        return $properties
    }
}
