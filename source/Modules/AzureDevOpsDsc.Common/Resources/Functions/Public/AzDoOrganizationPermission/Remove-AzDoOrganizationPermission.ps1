<#
.SYNOPSIS
Removes the managed identities' organization-level permissions.

.DESCRIPTION
Clears the ACEs of the identities named in Permissions from the organization root token.

The organization ACL itself is never deleted: it holds the grants every member of the organization
relies on, so deleting it the way the project-scoped permission resources delete theirs would lock
people out.

.PARAMETER GroupName
The group this configuration block is for (the resource key).

.PARAMETER Permissions
The ACEs whose identities are cleared.

.PARAMETER LookupResult
The lookup result from Get-AzDoOrganizationPermission.

.PARAMETER Ensure
Supplied by the DSC base class.

.PARAMETER Force
Supplied by the DSC base class.
#>
Function Remove-AzDoOrganizationPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoOrganizationPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Collection' -Type 'SecurityNamespaces'
    if (-not $SecurityNamespace)
    {
        throw "[Remove-AzDoOrganizationPermission] Security namespace 'Collection' not found. Nothing was changed."
    }

    $token = $LookupResult.aclToken
    if ([String]::IsNullOrWhiteSpace($token))
    {
        throw "[Remove-AzDoOrganizationPermission] The organization root token was not resolved ($($LookupResult.reason)). Nothing was changed."
    }

    $managedAces = @($LookupResult.ReferenceACLs | ForEach-Object { $_.aces } | Where-Object { $_ })
    if ($managedAces.Count -eq 0)
    {
        Write-Verbose "[Remove-AzDoOrganizationPermission] No managed identities resolved. Nothing to remove."
        return
    }

    $clearInput = @(
        @{
            token = @{ _token = $token }
            aces  = $managedAces
        }
    )

    Clear-AzDoACE -OrganizationName (Get-AzDoOrganizationName) -SecurityNamespaceID $SecurityNamespace.namespaceId -DifferenceACLs $clearInput
}
