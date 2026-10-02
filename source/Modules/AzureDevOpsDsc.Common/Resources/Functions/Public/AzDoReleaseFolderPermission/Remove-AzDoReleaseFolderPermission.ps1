<#
.SYNOPSIS
Removes the ACL from an Azure DevOps classic Release folder.

.DESCRIPTION
Removes the folder's entry in the 'ReleaseManagement' namespace, returning it to inheriting its
permissions from its parent.

Removing the ACL on the project release root is refused: it has no parent to inherit from, so
clearing it would leave every release definition in the project without an explicit grant.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER FolderPath
The Release folder path. Omit to target the project release root.

.PARAMETER isInherited
Whether the ACL inherits permissions from its parent.

.PARAMETER Permissions
The desired access control entries.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoReleaseFolderPermission -ProjectName 'Contoso' -FolderPath '\Platform' -isInherited $true
#>
Function Remove-AzDoReleaseFolderPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter()]
        [Alias('Path')]
        [System.String]$FolderPath,

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

    Write-Verbose "[Remove-AzDoReleaseFolderPermission] Started."

    if ([String]::IsNullOrWhiteSpace($FolderPath))
    {
        throw "[Remove-AzDoReleaseFolderPermission] FolderPath not specified, which targets the project release root. Removing the ACL on the project release root is not supported - it has no parent to inherit from."
    }

    $SecurityNamespace = Get-CacheItem -Key 'ReleaseManagement' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        throw "[Remove-AzDoReleaseFolderPermission] Security Namespace 'ReleaseManagement' not found."
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        Write-Verbose "[Remove-AzDoReleaseFolderPermission] No ACL token was resolved for '$FolderPath'. Nothing to remove."
        return
    }

    $DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
    $Filtered = $DescriptorACLList | Where-Object { $_.token -eq $token }

    if (-not $Filtered)
    {
        Write-Verbose "[Remove-AzDoReleaseFolderPermission] No ACL found for token '$token'. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoReleaseFolderPermission] Removing ACL for token '$token'."

    Remove-AzDoPermission -OrganizationName (Get-AzDoOrganizationName) `
        -SecurityNamespaceID $SecurityNamespace.namespaceId -TokenName $token

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
