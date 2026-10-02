<#
.SYNOPSIS
Applies the desired ACL to an Azure DevOps work item query folder.

.DESCRIPTION
Writes the permissions resolved by Get to the folder's 'WorkItemQueryFolders' ACL token.

The token is taken from the lookup result rather than recomputed, so that the ACL written here
is addressed to exactly the folder that Get compared against - recomputing it would reopen the
possibility of writing to a different folder than the one that was evaluated.

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
Set-AzDoQueryPermission -ProjectName 'Contoso' -QueryPath 'Shared Queries/Platform' -isInherited $true
#>
Function Set-AzDoQueryPermission
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

    Write-Verbose "[Set-AzDoQueryPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'WorkItemQueryFolders' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        Write-Error "[Set-AzDoQueryPermission] Security Namespace 'WorkItemQueryFolders' not found."
        return
    }

    $Project = Resolve-AzDoProject -ProjectName $ProjectName

    if ($null -eq $Project)
    {
        Write-Error "[Set-AzDoQueryPermission] Project not found: $ProjectName"
        return
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        Write-Error "[Set-AzDoQueryPermission] No ACL token was resolved for '$QueryPath' in project '$ProjectName'. Nothing was changed."
        return
    }

    # DescriptorACLList is intentionally empty: 'merge=false' on the Set-AzDoPermission POST
    # replaces the ACL per token, so only the tokens in the request body are touched. Merging in
    # the namespace-wide cache would grow the body with every other folder's ACL.
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = @()
        DescriptorMatchToken = $token
    }

    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
    }

    # Targeting the project's query root means there is no parent to inherit from, so stale ACEs
    # have to be cleared explicitly rather than being replaced by inheritance.
    if ([String]::IsNullOrWhiteSpace($QueryPath))
    {
        Write-Verbose "[Set-AzDoQueryPermission] Targeting the project query root. Clearing ACEs."
        $params.ClearACEs       = $true
        $params.DifferenceACLs  = $LookupResult.DifferenceACLs
    }

    Write-Verbose "[Set-AzDoQueryPermission] Setting query folder permissions for '$ProjectName' - '$token'."

    Set-AzDoPermission @params

    # Invalidate the LiveACLList cache so the next Get re-fetches from the API.
    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
