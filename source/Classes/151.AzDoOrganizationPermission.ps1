<#
.SYNOPSIS
    DSC resource for managing organization-level permissions.

.DESCRIPTION
    This resource manages permissions in the 'Collection' security namespace: the organization-level
    permissions shown under Organization settings > Permissions, such as 'Create new projects',
    'Edit instance-level information' and 'Manage enterprise policies'.

    The namespace has a single root token. The resource reads it from the live ACL rather than
    assuming its spelling, and reports an error if no root ACL is found. The root has no parent, so
    there is no isInherited property: the ACL's inheritance flag is written back as it was read.

    Only the identities listed in Permissions are managed. Every other identity's entry on the
    organization root is carried through unchanged when permissions are written, and removing the
    resource clears only the listed identities' entries. The organization ACL itself is never
    deleted.

.PARAMETER GroupName
    The group this configuration block is for. This is the key property, so each group can be
    configured in its own block. Use the format [OrganizationName]\GroupName or
    [TEAM FOUNDATION]\GroupName.

.PARAMETER Permissions
    An array of hashtables, each with an 'Identity' and a 'Permission' map from an action name
    (for example 'Create new projects') to 'Allow' or 'Deny'.

.EXAMPLE
    AzDoOrganizationPermission ProjectCreators
    {
        GroupName   = '[MyOrg]\Project Creators'
        Permissions = @(
            @{
                Identity   = '[MyOrg]\Project Creators'
                Permission = @{ 'Create new projects' = 'Allow' }
            }
        )
    }
#>

[DscResource()]
class AzDoOrganizationPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$GroupName

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoOrganizationPermission()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoOrganizationPermission] Get()
    {
        return [AzDoOrganizationPermission]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.GroupName    = $CurrentResourceObject.GroupName
        $properties.Permissions  = $CurrentResourceObject.Permissions
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure
        return $properties
    }
}
