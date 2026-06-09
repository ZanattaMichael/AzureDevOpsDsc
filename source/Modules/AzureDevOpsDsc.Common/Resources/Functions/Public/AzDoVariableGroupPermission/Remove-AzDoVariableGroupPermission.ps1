Function Remove-AzDoVariableGroupPermission
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

    Write-Verbose "[Remove-AzDoVariableGroupPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Library' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $VG                = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Type 'LiveVariableGroups'

    if ((-not $SecurityNamespace) -or (-not $Project)) { Write-Error "[Remove-AzDoVariableGroupPermission] Cache miss."; return }

    $tokenString = if ($VG) {
        'Library/Project/{0}/VariableGroup/{1}' -f $Project.id, $VG.id
    } else {
        'Library/Project/{0}' -f $Project.id
    }

    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $tokenString
    }

    Remove-AzDoPermission @params
}
