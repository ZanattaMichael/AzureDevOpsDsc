<#
.SYNOPSIS
    DSC resource for managing Azure DevOps service connection permissions.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoServiceConnectionPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Key, Mandatory)]
    [System.String]$ConnectionName

    [DscProperty(Key, Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoServiceConnectionPermission()
    {
        $this.Construct()
    }

    [AzDoServiceConnectionPermission] Get()
    {
        return [AzDoServiceConnectionPermission]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName      = $CurrentResourceObject.ProjectName
        $properties.ConnectionName   = $CurrentResourceObject.ConnectionName
        $properties.GroupName        = $CurrentResourceObject.GroupName
        $properties.isInherited      = $CurrentResourceObject.isInherited
        $properties.Permissions      = $CurrentResourceObject.Permissions
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoServiceConnectionPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}