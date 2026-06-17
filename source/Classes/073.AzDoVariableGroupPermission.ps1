<#
.SYNOPSIS
    DSC resource for managing Azure DevOps variable group permissions.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoVariableGroupPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$VariableGroupName

    [DscProperty(Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoVariableGroupPermission()
    {
        $this.Construct()
    }

    [AzDoVariableGroupPermission] Get()
    {
        return [AzDoVariableGroupPermission]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName         = $CurrentResourceObject.ProjectName
        $properties.VariableGroupName   = $CurrentResourceObject.VariableGroupName
        $properties.GroupName           = $CurrentResourceObject.GroupName
        $properties.isInherited         = $CurrentResourceObject.isInherited
        $properties.Permissions         = $CurrentResourceObject.Permissions
        $properties.LookupResult        = $CurrentResourceObject.LookupResult
        $properties.Ensure              = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoVariableGroupPermission] Current state properties: $($properties | Out-String)"

        return $properties
    }
}