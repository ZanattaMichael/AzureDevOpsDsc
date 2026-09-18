<#
.SYNOPSIS
Removes the ACL from an Azure DevOps pipeline folder.

.DESCRIPTION
Removes the folder's entry in the 'Build' namespace, returning it to inheriting its permissions
from its parent.

Removing the ACL on the project build root is refused: it has no parent to inherit from, so
clearing it would leave every pipeline in the project without an explicit grant.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER FolderPath
The pipeline folder path. Omit to target the project build root.

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
Remove-AzDoPipelineFolderPermission -ProjectName 'Contoso' -FolderPath '\Platform' -isInherited $true
#>
Function Remove-AzDoPipelineFolderPermission
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

    Write-Verbose "[Remove-AzDoPipelineFolderPermission] Started."

    if ([String]::IsNullOrWhiteSpace($FolderPath))
    {
        Write-Warning "[Remove-AzDoPipelineFolderPermission] FolderPath not specified, which targets the project build root."
        Write-Warning "[Remove-AzDoPipelineFolderPermission] STOPPING. Removing the ACL on the project build root is not supported - it has no parent to inherit from."
        return
    }

    $SecurityNamespace = Get-CacheItem -Key 'Build' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        Write-Error "[Remove-AzDoPipelineFolderPermission] Security Namespace 'Build' not found."
        return
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        Write-Verbose "[Remove-AzDoPipelineFolderPermission] No ACL token was resolved for '$FolderPath'. Nothing to remove."
        return
    }

    $DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
    $Filtered = $DescriptorACLList | Where-Object { $_.token -eq $token }

    if (-not $Filtered)
    {
        Write-Verbose "[Remove-AzDoPipelineFolderPermission] No ACL found for token '$token'. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoPipelineFolderPermission] Removing ACL for token '$token'."

    Remove-AzDoPermission -OrganizationName (Get-AzDoOrganizationName) `
        -SecurityNamespaceID $SecurityNamespace.namespaceId -TokenName $token

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
