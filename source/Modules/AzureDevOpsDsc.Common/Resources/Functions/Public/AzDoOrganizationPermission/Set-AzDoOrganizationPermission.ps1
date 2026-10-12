<#
.SYNOPSIS
Applies organization-level permissions.

.DESCRIPTION
Writes the desired ACEs to the organization root token resolved by Get-AzDoOrganizationPermission.

The ACL POST replaces the whole ACL for the token, so every live ACE for an identity this resource
does not manage is added to the body unchanged (Merge-AzDoUnmanagedACE). Without that, writing one
group's permissions would strip every other grant at the organization level.

.PARAMETER GroupName
The group this configuration block is for (the resource key).

.PARAMETER Permissions
The desired ACEs.

.PARAMETER LookupResult
The lookup result from Get-AzDoOrganizationPermission.

.PARAMETER Ensure
Supplied by the DSC base class.

.PARAMETER Force
Supplied by the DSC base class.
#>
Function Set-AzDoOrganizationPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoOrganizationPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Collection' -Type 'SecurityNamespaces'
    if (-not $SecurityNamespace)
    {
        throw "[Set-AzDoOrganizationPermission] Security namespace 'Collection' not found. Nothing was changed."
    }

    # Get reports Error, which still routes here, when it could not find the root token.
    $token = $LookupResult.aclToken
    if ([String]::IsNullOrWhiteSpace($token))
    {
        throw "[Set-AzDoOrganizationPermission] The organization root token was not resolved ($($LookupResult.reason)). Nothing was changed."
    }

    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = @()
        DescriptorMatchToken = '^{0}$' -f [regex]::Escape($token)
    }

    $serializedACLs = ConvertTo-ACLHashtable @serializeACLParams
    $serializedACLs = Merge-AzDoUnmanagedACE -SerializedACLs $serializedACLs -LiveACLs $LookupResult.LiveACLs

    $params = @{
        OrganizationName    = Get-AzDoOrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = $serializedACLs
    }

    Set-AzDoPermission @params
}
