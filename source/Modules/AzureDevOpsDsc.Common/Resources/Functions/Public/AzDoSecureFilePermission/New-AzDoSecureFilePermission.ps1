<#
.SYNOPSIS
Applies the desired ACL to an Azure DevOps secure file.

.DESCRIPTION
Writes the permissions resolved by Get to the secure file's 'Library' ACL token.

The token is taken from the lookup result rather than recomputed, so the ACL written is
addressed to exactly the secure file that Get compared against.

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
New-AzDoSecureFilePermission -ProjectName 'Contoso' -SecureFileName 'signing.pfx' -isInherited $true
#>
Function New-AzDoSecureFilePermission
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

    Write-Verbose "[New-AzDoSecureFilePermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Library' -Type 'SecurityNamespaces'

    if ($null -eq $SecurityNamespace)
    {
        Write-Error "[New-AzDoSecureFilePermission] Security Namespace 'Library' not found."
        return
    }

    $token = $LookupResult.aclToken

    if ([String]::IsNullOrWhiteSpace($token))
    {
        Write-Error "[New-AzDoSecureFilePermission] No ACL token was resolved for '$SecureFileName' in project '$ProjectName'. Nothing was changed."
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

    if ([String]::IsNullOrWhiteSpace($SecureFileName))
    {
        Write-Verbose "[New-AzDoSecureFilePermission] Targeting the project Library root. Clearing ACEs."
        $params.ClearACEs      = $true
        $params.DifferenceACLs = $LookupResult.DifferenceACLs
    }

    Write-Verbose "[New-AzDoSecureFilePermission] Setting secure file permissions for token '$token'."

    Set-AzDoPermission @params

    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
}
