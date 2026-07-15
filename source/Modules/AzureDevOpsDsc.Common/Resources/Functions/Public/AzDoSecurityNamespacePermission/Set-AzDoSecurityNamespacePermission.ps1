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
    # DescriptorACLList intentionally empty: 'merge=false' on the Set-AzDoPermission POST replaces the
    # ACL per-token (only tokens present in the request body are touched), so there is no need to
    # re-submit every other token's ACL. Merging in the whole namespace-wide 'LiveACLList' cache (as
    # this used to) meant the request body grew with the size of the ENTIRE org's cached ACLs for this
    # namespace - confirmed via a live wire-level capture to reach ~11,000 lines of JSON for a single
    # ACE update, after which the API accepted the POST but the write silently never persisted. This
    # already matches Set-AzDoProcessPermission and Set-AzDoProjectPermission, which never had this bug.
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = @()
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
