<#
.SYNOPSIS
Applies Azure DevOps Process permissions (new ACL).

.DESCRIPTION
Serializes the desired Process namespace ACEs and applies them to the resolved process scope token via
Set-AzDoPermission. Other identities' ACEs on the same token are preserved.

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
function New-AzDoProcessPermission
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

    Write-Verbose "[New-AzDoProcessPermission] Started."

    $OrganizationName  = (Get-AzDoOrganizationName)
    $SecurityNamespace = Get-CacheItem -Key 'Process' -Type 'SecurityNamespaces'

    if (-not $SecurityNamespace)
    {
        Write-Error "[New-AzDoProcessPermission] Security namespace 'Process' not found."
        return
    }

    $processToken = Get-DevOpsProcessAclToken -ProcessName $ProcessName -OrganizationName $OrganizationName
    if (-not $processToken)
    {
        Write-Error "[New-AzDoProcessPermission] Could not resolve a Process ACL token for '$ProcessName'."
        return
    }

    # Preserve every other token's ACL; replace only the one we manage (exact, escaped match).
    $descriptorMatchToken = '^{0}$' -f [regex]::Escape($processToken)

    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = $descriptorMatchToken
    }

    $params = @{
        OrganizationName    = $OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
    }

    Set-AzDoPermission @params
}
