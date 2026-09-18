<#
.SYNOPSIS
Removes the ACL from an Azure DevOps work item query folder.

.DESCRIPTION
Removes the folder's entry in the 'WorkItemQueryFolders' namespace, which returns the folder to
inheriting its permissions from its parent.

Removing the ACL on the project's query root is refused: that token has no parent to inherit
from, so clearing it would leave every query in the project without an explicit grant.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER QueryPath
The full path of the query folder. Omit to target the project's query root.

.PARAMETER isInherited
Whether the ACL inherits permissions from its parent.

.PARAMETER Permissions
The desired access control entries.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoQueryPermission -ProjectName 'Contoso' -QueryPath 'Shared Queries/Platform' -isInherited $true
#>
Function Remove-AzDoQueryPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $false)]
        [Alias('Path')]
        [System.String]$QueryPath,

        [Parameter(Mandatory = $true)]
        [System.Boolean]$isInherited,

        [Parameter()]
        [HashTable[]]$Permissions,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoQueryPermission] Started."

    if ([String]::IsNullOrWhiteSpace($QueryPath))
    {
        Write-Warning "[Remove-AzDoQueryPermission] QueryPath not specified, which targets the project query root."
        Write-Warning "[Remove-AzDoQueryPermission] STOPPING. Removing the ACL on the project query root is not supported - it has no parent to inherit from."
        return
    }

    $SecurityNamespace = Get-CacheItem -Key 'WorkItemQueryFolders' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        Write-Error "[Remove-AzDoQueryPermission] Security Namespace 'WorkItemQueryFolders' not found."
        return
    }

    $Project = Resolve-AzDoProject -ProjectName $ProjectName

    if ($null -eq $Project)
    {
        Write-Error "[Remove-AzDoQueryPermission] Project not found: $ProjectName"
        return
    }

    $DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'

    if ($null -eq $DescriptorACLList)
    {
        Write-Error "[Remove-AzDoQueryPermission] ACLs not found."
        return
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        Write-Verbose "[Remove-AzDoQueryPermission] No ACL token was resolved for '$QueryPath'. Nothing to remove."
        return
    }

    # Only remove an ACL that actually exists for this token, so that a Remove on an already-clean
    # folder is a no-op rather than an error.
    $Filtered = $DescriptorACLList | Where-Object { $_.token -eq $token }

    if (-not $Filtered)
    {
        Write-Verbose "[Remove-AzDoQueryPermission] No ACL found for token '$token'. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoQueryPermission] Removing ACL for token '$token'."

    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $token
    }

    Remove-AzDoPermission @params

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
