Function Set-AzDoAgentPoolPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$PoolName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Set-AzDoAgentPoolPermission] Started."
    $SecurityNamespace = Get-CacheItem -Key 'AgentPools' -Type 'SecurityNamespaces'
    $Pool              = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    if (-not $SecurityNamespace) { Write-Error "[Set-AzDoAgentPoolPermission] Namespace not found."; return }
    $matchToken = if ($Pool) { $LocalizedDataAzSerializationPatten.AgentPoolPermission -f $Pool.id } else { '.*' }
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = $matchToken
    }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
        ClearACEs           = $true
        DifferenceACLs      = $LookupResult.DifferenceACLs
    }
    Set-AzDoPermission @params
}
