<#
.SYNOPSIS
Applies the desired ACL to an Azure DevOps classic Release definition.

.DESCRIPTION
Writes the permissions resolved by Get to the Release definition's 'ReleaseManagement' ACL token.

Throws when the security namespace cannot be found or no ACL token was resolved, so a caller
applying this resource via Invoke-DscResource sees the failure rather than Set() reporting
success.

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
The lookup result produced by Get-AzDoReleaseDefinitionPermission.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoReleaseDefinitionPermission -ProjectName 'Contoso' -DefinitionName 'Platform Release' -isInherited $true
#>
Function Set-AzDoReleaseDefinitionPermission
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

    Write-Verbose "[Set-AzDoReleaseDefinitionPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'ReleaseManagement' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        throw "[Set-AzDoReleaseDefinitionPermission] Security Namespace 'ReleaseManagement' not found."
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        throw "[Set-AzDoReleaseDefinitionPermission] No ACL token was resolved for release definition '$DefinitionName'. The definition may not exist."
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

    Write-Verbose "[Set-AzDoReleaseDefinitionPermission] Setting release definition permissions for token '$token'."

    Set-AzDoPermission @params

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
