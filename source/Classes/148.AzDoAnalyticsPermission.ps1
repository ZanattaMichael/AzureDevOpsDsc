<#
.SYNOPSIS
    DSC resource for managing project-level Analytics ACL permissions.
.DESCRIPTION
    This resource manages permissions in the 'Analytics' security namespace, controlling
    Power BI / OData access to a project's work-tracking analytics data. The namespace's ACL
    token shape is '$/{projectId}'.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER GroupName
    The name of the group to grant permissions to. This is a key property. Use the format [ProjectName]\GroupName or [TEAM FOUNDATION]\GroupName for organization-level groups.

.PARAMETER isInherited
    Whether permissions are inherited from parent objects. Defaults to $true.

.PARAMETER Permissions
    An array of hashtables mapping an action name (e.g. 'View analytics') to 'Allow' or 'Deny'.

#>

[DscResource()]
class AzDoAnalyticsPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoAnalyticsPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoAnalyticsPermission] Get()
    {
        return [AzDoAnalyticsPermission]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName  = $CurrentResourceObject.ProjectName
        $properties.GroupName    = $CurrentResourceObject.GroupName
        $properties.isInherited  = $CurrentResourceObject.isInherited
        $properties.Permissions  = $CurrentResourceObject.Permissions
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure
        return $properties
    }
}
