<#
.SYNOPSIS
Applies the desired ACL to an Azure DevOps classic Release folder.

.DESCRIPTION
Writes the permissions resolved by Get to the Release folder's 'ReleaseManagement' ACL token.

Throws when the security namespace cannot be found or no ACL token was resolved, so a caller
applying this resource via Invoke-DscResource sees the failure rather than Set() reporting
success.

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
New-AzDoReleaseFolderPermission -ProjectName 'Contoso' -FolderPath '\Platform' -isInherited $true
#>
Function New-AzDoReleaseFolderPermission
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

    Write-Verbose "[New-AzDoReleaseFolderPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'ReleaseManagement' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        throw "[New-AzDoReleaseFolderPermission] Security Namespace 'ReleaseManagement' not found."
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        throw "[New-AzDoReleaseFolderPermission] No ACL token was resolved for '$FolderPath' in project '$ProjectName'. Nothing was changed."
    }

    # DescriptorACLList is intentionally empty: 'merge=false' replaces the ACL per token, so only
    # the tokens in the request body are touched.
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

    if ([String]::IsNullOrWhiteSpace($FolderPath))
    {
        Write-Verbose "[New-AzDoReleaseFolderPermission] Targeting the project release root. Clearing ACEs."
        $params.ClearACEs      = $true
        $params.DifferenceACLs = $LookupResult.DifferenceACLs
    }

    Write-Verbose "[New-AzDoReleaseFolderPermission] Setting release folder permissions for token '$token'."

    Set-AzDoPermission @params

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
