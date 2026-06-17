Function Remove-AzDoSecurityNamespacePermission
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
    Write-Verbose "[Remove-AzDoSecurityNamespacePermission] Started."
    $ns = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $ns) { Write-Error "[Remove-AzDoSecurityNamespacePermission] Namespace not found."; return }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $ns.namespaceId
        TokenName           = $Token
    }
    Remove-AzDoPermission @params
}
