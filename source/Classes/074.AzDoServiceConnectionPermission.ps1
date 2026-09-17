<#
.SYNOPSIS
    DSC resource for managing Azure DevOps service connection permissions.
.DESCRIPTION
    This resource manages security permissions on Azure DevOps service connections, controlling
    which groups or users can use or manage specific service connections in pipelines.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER ConnectionName
    The name of the service connection. This is a key property.

.PARAMETER GroupName
    The name of the group to grant permissions to. This is a key property. Use the format [ProjectName]\GroupName.

.PARAMETER isInherited
    Whether permissions are inherited. Defaults to $true.

#>

[DscResource()]
class AzDoServiceConnectionPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$ConnectionName

    [DscProperty(Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoServiceConnectionPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
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
