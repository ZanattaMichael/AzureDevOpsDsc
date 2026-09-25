<#
.SYNOPSIS
Removes the ACL from an Azure DevOps classic Release definition.

.DESCRIPTION
Removes the definition's entry in the 'ReleaseManagement' namespace, returning it to inheriting
its permissions from its folder (or the release root).

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER DefinitionName
The name of the Release definition.

.PARAMETER FolderPath
The Release folder the definition lives in. Omit when the definition lives at the release root,
or when its name is unique across the project.

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
Remove-AzDoReleaseDefinitionPermission -ProjectName 'Contoso' -DefinitionName 'Platform Release' -isInherited $true
#>
Function Remove-AzDoReleaseDefinitionPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$DefinitionName,

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

    Write-Verbose "[Remove-AzDoReleaseDefinitionPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'ReleaseManagement' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        throw "[Remove-AzDoReleaseDefinitionPermission] Security Namespace 'ReleaseManagement' not found."
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        Write-Verbose "[Remove-AzDoReleaseDefinitionPermission] No ACL token was resolved for release definition '$DefinitionName'. Nothing to remove."
        return
    }

    $DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
    $Filtered = $DescriptorACLList | Where-Object { $_.token -eq $token }

    if (-not $Filtered)
    {
        Write-Verbose "[Remove-AzDoReleaseDefinitionPermission] No ACL found for token '$token'. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoReleaseDefinitionPermission] Removing ACL for token '$token'."

    Remove-AzDoPermission -OrganizationName (Get-AzDoOrganizationName) `
        -SecurityNamespaceID $SecurityNamespace.namespaceId -TokenName $token

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
