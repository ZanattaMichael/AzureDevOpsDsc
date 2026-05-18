<#
.SYNOPSIS
    DSC resource for managing generic Azure DevOps security namespace permissions.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoSecurityNamespacePermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$SecurityNamespace

    [DscProperty(Key, Mandatory)]
    [System.String]$Token

    [DscProperty(Key, Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoSecurityNamespacePermission()
    {
        $this.Construct()
    }

    [AzDoSecurityNamespacePermission] Get()
    {
        return [AzDoSecurityNamespacePermission]$($this.GetDscCurrentStateProperties())
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

        $properties.SecurityNamespace = $CurrentResourceObject.SecurityNamespace
        $properties.Token             = $CurrentResourceObject.Token
        $properties.GroupName         = $CurrentResourceObject.GroupName
        $properties.isInherited       = $CurrentResourceObject.isInherited
        $properties.Permissions       = $CurrentResourceObject.Permissions
        $properties.LookupResult      = $CurrentResourceObject.LookupResult
        $properties.Ensure            = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoSecurityNamespacePermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}