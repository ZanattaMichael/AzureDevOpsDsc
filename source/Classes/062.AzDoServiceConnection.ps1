<#
.SYNOPSIS
    DSC resource for managing Azure DevOps service connections.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoServiceConnection : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$ConnectionName

    [DscProperty(Mandatory)]
    [System.String]$ConnectionType

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.Boolean]$AllowAllPipelines = $false

    [DscProperty()]
    [HashTable]$Authorization

    [DscProperty()]
    [HashTable]$Data

    AzDoServiceConnection()
    {
        $this.Construct()
    }

    [AzDoServiceConnection] Get()
    {
        return [AzDoServiceConnection]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @('ConnectionType')
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName      = $CurrentResourceObject.ProjectName
        $properties.ConnectionName   = $CurrentResourceObject.ConnectionName
        $properties.ConnectionType   = $CurrentResourceObject.ConnectionType
        $properties.Description      = $CurrentResourceObject.Description
        $properties.AllowAllPipelines = $CurrentResourceObject.AllowAllPipelines
        $properties.Authorization    = $CurrentResourceObject.Authorization
        $properties.Data             = $CurrentResourceObject.Data
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure
        Write-Verbose "[AzDoServiceConnection] Current state properties: $($properties | Out-String)"
        return $properties
    }
}