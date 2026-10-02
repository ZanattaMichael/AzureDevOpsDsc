Function Remove-AzDoTaggingPermission
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

    Write-Verbose "[Remove-AzDoTaggingPermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Tagging' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if ((-not $SecurityNamespace) -or (-not $Project))
    {
        throw "[Remove-AzDoTaggingPermission] Security namespace or project not found. Cannot converge on '$ProjectName'."
    }

    $tokenString = '/{0}' -f $Project.id

    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $tokenString
    }

    Remove-AzDoPermission @params
}
