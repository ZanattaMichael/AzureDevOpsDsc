Function Remove-AzDoEnvironmentPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$EnvironmentName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoEnvironmentPermission] Started."
    $SecurityNamespace = Get-CacheItem -Key 'DistributedTask' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $Env               = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'
    if ((-not $SecurityNamespace) -or (-not $Project)) { Write-Error "[Remove-AzDoEnvironmentPermission] Cache miss."; return }
    $tokenString = if ($Env) {
        'Environments/{0}/{1}' -f $Project.id, $Env.id
    } else {
        'Environments/{0}' -f $Project.id
    }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $tokenString
    }
    Remove-AzDoPermission @params
}
