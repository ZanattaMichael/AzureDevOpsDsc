Function Set-AzDoSecurityNamespacePermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$SecurityNamespace,
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Set-AzDoSecurityNamespacePermission] Started."
    $ns = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $ns) { Write-Error "[Set-AzDoSecurityNamespacePermission] Namespace not found."; return }
    # New-ACLToken strips [ ] from token names. Strip here too so DescriptorMatchToken matches the
    # live ACL token (e.g. "$/TEST_SNS_PERM") not the bracketed form ("$/[TEST_SNS_PERM]").
    $strippedToken = $Token.Replace('[', '').Replace(']', '')
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = Get-CacheItem -Key $ns.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = ($LocalizedDataAzSerializationPatten.GenericPermission -f [regex]::Escape($strippedToken))
    }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $ns.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
        ClearACEs           = $true
        DifferenceACLs      = $LookupResult.DifferenceACLs
    }
    Set-AzDoPermission @params
}
