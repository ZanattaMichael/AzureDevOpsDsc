<#
.SYNOPSIS
Updates Azure DevOps Process permissions (existing ACL).

.DESCRIPTION
Serializes the desired Process namespace ACEs and applies them to the resolved process scope token via
Set-AzDoPermission, reconciling drift detected by Get-AzDoProcessPermission.

.PARAMETER ProcessName
The process name, or the sentinel 'AllProcesses' for the org-wide root scope.

.PARAMETER Permissions
An array of hashtables describing the desired ACEs.

.PARAMETER isInherited
Whether the ACL inherits permissions.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation.
#>
function Set-AzDoProcessPermission
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,

        [Parameter()]
        [HashTable[]]$Permissions,

        [Parameter()]
        [bool]$isInherited = $true,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoProcessPermission] Started."

    $OrganizationName  = (Get-AzDoOrganizationName)
    $SecurityNamespace = Get-CacheItem -Key 'Process' -Type 'SecurityNamespaces'

    if (-not $SecurityNamespace)
    {
        Write-Error "[Set-AzDoProcessPermission] Security namespace 'Process' not found."
        return
    }

    $processToken = Get-DevOpsProcessAclToken -ProcessName $ProcessName -OrganizationName $OrganizationName
    if (-not $processToken)
    {
        Write-Error "[Set-AzDoProcessPermission] Could not resolve a Process ACL token for '$ProcessName'."
        return
    }

    $descriptorMatchToken = '^{0}$' -f [regex]::Escape($processToken)

    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = @()
        DescriptorMatchToken = $descriptorMatchToken
    }

    $params = @{
        OrganizationName    = $OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
    }

    Set-AzDoPermission @params
}
