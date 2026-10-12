<#
.SYNOPSIS
Removes the managed identities' task group permissions.

.DESCRIPTION
Clears the ACEs of the identities named in Permissions from the 'MetaTask' token. The ACL itself is
not deleted, so ACEs this resource does not manage, such as the creator's, are kept.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER TaskGroupName
The name of the task group. Omit to target the project level.

.PARAMETER isInherited
Whether the ACL inherits permissions from the project level.

.PARAMETER Permissions
The ACEs whose identities are cleared.

.PARAMETER LookupResult
The lookup result from Get-AzDoTaskGroupPermission.

.PARAMETER Ensure
Supplied by the DSC base class.

.PARAMETER Force
Supplied by the DSC base class.
#>
Function Remove-AzDoTaskGroupPermission
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

    Write-Verbose "[Remove-AzDoTaskGroupPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'MetaTask' -Type 'SecurityNamespaces'
    if (-not $SecurityNamespace)
    {
        throw "[Remove-AzDoTaskGroupPermission] Security namespace 'MetaTask' not found. Nothing was changed."
    }

    $token = $LookupResult.aclToken
    if ([String]::IsNullOrWhiteSpace($token))
    {
        throw "[Remove-AzDoTaskGroupPermission] No ACL token was resolved for project '$ProjectName' ($($LookupResult.reason)). Nothing was changed."
    }

    $managedAces = @($LookupResult.ReferenceACLs | ForEach-Object { $_.aces } | Where-Object { $_ })
    if ($managedAces.Count -eq 0)
    {
        Write-Verbose "[Remove-AzDoTaskGroupPermission] No managed identities resolved. Nothing to remove."
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
