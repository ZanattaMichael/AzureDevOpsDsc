<#
.SYNOPSIS
Applies the desired ACL to an Azure DevOps pipeline folder.

.DESCRIPTION
Writes the permissions resolved by Get to the pipeline folder's 'Build' ACL token.

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
Set-AzDoPipelineFolderPermission -ProjectName 'Contoso' -FolderPath '\Platform' -isInherited $true
#>
Function Set-AzDoPipelineFolderPermission
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

    Write-Verbose "[Set-AzDoPipelineFolderPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Build' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        Write-Error "[Set-AzDoPipelineFolderPermission] Security Namespace 'Build' not found."
        return
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        Write-Error "[Set-AzDoPipelineFolderPermission] No ACL token was resolved for '$FolderPath' in project '$ProjectName'. Nothing was changed."
        return
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
        Write-Verbose "[Set-AzDoPipelineFolderPermission] Targeting the project build root. Clearing ACEs."
        $params.ClearACEs      = $true
        $params.DifferenceACLs = $LookupResult.DifferenceACLs
    }

    Write-Verbose "[Set-AzDoPipelineFolderPermission] Setting pipeline folder permissions for token '$token'."

    Set-AzDoPermission @params

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
