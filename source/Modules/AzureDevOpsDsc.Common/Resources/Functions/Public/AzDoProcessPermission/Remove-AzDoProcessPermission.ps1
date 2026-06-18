<#
.SYNOPSIS
Removes Azure DevOps Process permissions from a process scope token.

.DESCRIPTION
Removes the managed ACL for the resolved process scope token via Remove-AzDoPermission. Protected
system ACEs cannot be removed by the API and remain.

.PARAMETER ProcessName
The process name, or the sentinel 'AllProcesses' for the org-wide root scope.

.PARAMETER Permissions
An array of hashtables describing the ACEs (unused on removal; present for signature parity).

.PARAMETER isInherited
Whether the ACL inherits permissions.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation.
#>
function Remove-AzDoProcessPermission
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

    Write-Verbose "[Remove-AzDoProcessPermission] Started."

    $OrganizationName  = (Get-AzDoOrganizationName)
    $SecurityNamespace = Get-CacheItem -Key 'Process' -Type 'SecurityNamespaces'

    if (-not $SecurityNamespace)
    {
        Write-Error "[Remove-AzDoProcessPermission] Security namespace 'Process' not found."
        return
    }

    $processToken = Get-DevOpsProcessAclToken -ProcessName $ProcessName -OrganizationName $OrganizationName
    if (-not $processToken)
    {
        Write-Error "[Remove-AzDoProcessPermission] Could not resolve a Process ACL token for '$ProcessName'."
        return
    }

    $params = @{
        OrganizationName    = $OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $processToken
    }

    Remove-AzDoPermission @params
}
