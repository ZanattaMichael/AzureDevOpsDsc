Function New-AzDoSecurityNamespacePermission
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
    Write-Verbose "[New-AzDoSecurityNamespacePermission] Started."
    $ns = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $ns) { Write-Error "[New-AzDoSecurityNamespacePermission] Namespace not found."; return }
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = Get-CacheItem -Key $ns.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = ($LocalizedDataAzSerializationPatten.GenericPermission -f [regex]::Escape($Token))
    }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $ns.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
    }
    Set-AzDoPermission @params
}
