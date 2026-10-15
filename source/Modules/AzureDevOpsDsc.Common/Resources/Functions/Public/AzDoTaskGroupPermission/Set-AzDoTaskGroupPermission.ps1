<#
.SYNOPSIS
Applies task group permissions.

.DESCRIPTION
Writes the desired ACEs to the 'MetaTask' token resolved by Get-AzDoTaskGroupPermission.

The ACL POST replaces the whole ACL for the token, so every live ACE for an identity this resource
does not manage is added to the body unchanged (Merge-AzDoUnmanagedACE).

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TaskGroupName
The name of the task group. Omit to target the project level.

.PARAMETER isInherited
Whether the ACL inherits permissions from the project level.

.PARAMETER Permissions
The desired ACEs.

.PARAMETER LookupResult
The lookup result from Get-AzDoTaskGroupPermission.

.PARAMETER Ensure
Supplied by the DSC base class.

.PARAMETER Force
Supplied by the DSC base class.
#>
Function Set-AzDoTaskGroupPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter()][string]$TaskGroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoTaskGroupPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'MetaTask' -Type 'SecurityNamespaces'
    if (-not $SecurityNamespace)
    {
        throw "[Set-AzDoTaskGroupPermission] Security namespace 'MetaTask' not found. Nothing was changed."
    }

    # New is also routed here when Get found no project or task group, so there is no token.
    $token = $LookupResult.aclToken
    if ([String]::IsNullOrWhiteSpace($token))
    {
        throw "[Set-AzDoTaskGroupPermission] No ACL token was resolved for project '$ProjectName' ($($LookupResult.reason)). Nothing was changed."
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
