Function Remove-AzDoProjectPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoProjectPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Project' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if ((-not $SecurityNamespace) -or (-not $Project))
    {
        Write-Error "[Remove-AzDoProjectPermission] Security namespace or project not found."
        return
    }

    $tokenString = '$PROJECT:vstfs:///Classification/TeamProject/{0}' -f $Project.id

    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $tokenString
    }

    Remove-AzDoPermission @params
}
