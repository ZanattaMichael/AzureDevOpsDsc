<#
.SYNOPSIS
    DSC resource for managing deployment environment ACL permissions.
.DESCRIPTION
    This resource manages security permissions on Azure DevOps pipeline environments, controlling
    which groups or users can view, use, or administer specific environments.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER EnvironmentName
    The name of the pipeline environment. This is a key property.

.PARAMETER GroupName
    The name of the group to grant permissions to. This is a key property. Use the format [ProjectName]\GroupName.

.PARAMETER isInherited
    Whether permissions are inherited. Defaults to $true.

#>

[DscResource()]
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

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
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
