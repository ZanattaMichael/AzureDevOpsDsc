<#
.SYNOPSIS
Removes the ACL from an Azure DevOps secure file.

.DESCRIPTION
Removes the secure file's entry in the 'Library' namespace, returning it to inheriting its
permissions from the project Library root.

Removing the ACL on the project Library root itself is refused: it has no parent to inherit
from, so clearing it would leave every secure file and variable group in the project without an
explicit grant.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER SecureFileName
The name of the secure file. Omit to target the project Library root.

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
Remove-AzDoSecureFilePermission -ProjectName 'Contoso' -SecureFileName 'signing.pfx' -isInherited $true
#>
Function Remove-AzDoSecureFilePermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter()]
        [Alias('FileName')]
        [System.String]$SecureFileName,

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

    Write-Verbose "[Remove-AzDoSecureFilePermission] Started."

    if ([String]::IsNullOrWhiteSpace($SecureFileName))
    {
        Write-Warning "[Remove-AzDoSecureFilePermission] SecureFileName not specified, which targets the project Library root."
        Write-Warning "[Remove-AzDoSecureFilePermission] STOPPING. Removing the ACL on the project Library root is not supported - it has no parent to inherit from."
        return
    }

    $SecurityNamespace = Get-CacheItem -Key 'Library' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        Write-Error "[Remove-AzDoSecureFilePermission] Security Namespace 'Library' not found."
        return
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        Write-Verbose "[Remove-AzDoSecureFilePermission] No ACL token was resolved for '$SecureFileName'. Nothing to remove."
        return
    }

    $DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
    $Filtered = $DescriptorACLList | Where-Object { $_.token -eq $token }

    if (-not $Filtered)
    {
        Write-Verbose "[Remove-AzDoSecureFilePermission] No ACL found for token '$token'. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoSecureFilePermission] Removing ACL for token '$token'."

    Remove-AzDoPermission -OrganizationName (Get-AzDoOrganizationName) `
        -SecurityNamespaceID $SecurityNamespace.namespaceId -TokenName $token

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
