<#
.SYNOPSIS
    DSC resource for managing deployment environment ACL permissions.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoEnvironmentPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$EnvironmentName

    [DscProperty(Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoEnvironmentPermission()
    {
        $this.Construct()
    }

    [AzDoEnvironmentPermission] Get()
    {
        return [AzDoEnvironmentPermission]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName     = $CurrentResourceObject.ProjectName
        $properties.EnvironmentName = $CurrentResourceObject.EnvironmentName
        $properties.GroupName       = $CurrentResourceObject.GroupName
        $properties.isInherited     = $CurrentResourceObject.isInherited
        $properties.Permissions     = $CurrentResourceObject.Permissions
        $properties.LookupResult    = $CurrentResourceObject.LookupResult
        $properties.Ensure          = $CurrentResourceObject.Ensure
        return $properties
    }
}