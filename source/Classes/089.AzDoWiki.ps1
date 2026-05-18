<#
.SYNOPSIS
    DSC resource for managing Azure DevOps project and code wikis.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoWiki : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
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