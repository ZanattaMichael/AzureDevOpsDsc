<#
.SYNOPSIS
    DSC resource for managing Azure DevOps Process namespace permissions.

.DESCRIPTION
    The AzDoProcessPermission resource manages ACEs in the Process security namespace. Use the sentinel
    process name 'AllProcesses' to manage the org-wide root scope ('$PROCESS') — this governs who can
    create, edit, delete and administer processes, including creating inherited (child) processes from
    existing ones. A specific inherited process name scopes permissions to that single process
    ('$PROCESS:{parentProcessTypeId}:{processTypeId}').

    It inherits Test()/Set() from the AzDevOpsDscResourceBase class.

.PARAMETER ProcessName
    The process name, or the sentinel 'AllProcesses' for the org-wide root scope.

.PARAMETER isInherited
    Whether the ACL inherits permissions. Defaults to $true.

.PARAMETER Permissions
    An array of hashtables describing the desired ACEs, each with an 'Identity' and a 'Permission' map.

.EXAMPLE
    # Allow the 'Process Authors' group to create inherited processes org-wide.
    AzDoProcessPermission AllowCreate
    {
        ProcessName = 'AllProcesses'
        Permissions = @(
            @{
                Identity   = '[MyOrg]\Process Authors'
                Permission = @{ Create = 'Allow'; Edit = 'Allow' }
            }
        )
    }
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoProcessPermission : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProcessName

    [DscProperty()]
    [System.Boolean]$isInherited = $true

    [DscProperty()]
    [HashTable[]]$Permissions

    AzDoProcessPermission()
    {
        $this.Construct()
    }

    [AzDoProcessPermission] Get()
    {
        return [AzDoProcessPermission]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProcessName  = $CurrentResourceObject.ProcessName
        $properties.isInherited  = $CurrentResourceObject.isInherited
        $properties.Permissions  = $CurrentResourceObject.Permissions
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure
        return $properties
    }
}
