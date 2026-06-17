<#
.SYNOPSIS
    DSC resource for managing pipeline check configurations.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoCheckConfiguration : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$TargetResourceName

    [DscProperty(Mandatory)]
    [ValidateSet('environment','repository','endpoint')]
    [System.String]$ResourceType

    [DscProperty(Mandatory)]
    [System.String]$CheckType

    [DscProperty()]
    [HashTable]$Settings

    [DscProperty()]
    [System.UInt32]$TimeoutInMinutes = 43200

    [DscProperty()]
    [System.Boolean]$Enabled = $true

    AzDoCheckConfiguration()
    {
        $this.Construct()
    }

    [AzDoCheckConfiguration] Get()
    {
        return [AzDoCheckConfiguration]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName          = $CurrentResourceObject.ProjectName
        $properties.TargetResourceName   = $CurrentResourceObject.TargetResourceName
        $properties.ResourceType         = $CurrentResourceObject.ResourceType
        $properties.CheckType        = $CurrentResourceObject.CheckType
        $properties.Settings         = $CurrentResourceObject.Settings
        $properties.TimeoutInMinutes = $CurrentResourceObject.TimeoutInMinutes
        $properties.Enabled          = $CurrentResourceObject.Enabled
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure
        return $properties
    }
}