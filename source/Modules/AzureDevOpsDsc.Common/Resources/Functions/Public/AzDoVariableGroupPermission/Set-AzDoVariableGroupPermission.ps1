Function Set-AzDoVariableGroupPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$VariableGroupName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoVariableGroupPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Library' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if ((-not $SecurityNamespace) -or (-not $Project)) { Write-Error "[Set-AzDoVariableGroupPermission] Cache miss."; return }

    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = ($LocalizedDataAzSerializationPatten.LibraryPermission -f $Project.id)
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
