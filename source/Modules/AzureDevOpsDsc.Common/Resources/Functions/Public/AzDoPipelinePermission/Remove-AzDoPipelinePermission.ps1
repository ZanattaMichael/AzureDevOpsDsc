Function Remove-AzDoPipelinePermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$PipelineName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoPipelinePermission] Started."

    $SecurityNamespace = Get-CacheItem -Key 'Build' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $Pipeline          = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Type 'LivePipelines'

    if ((-not $SecurityNamespace) -or (-not $Project))
    {
        Write-Error "[Remove-AzDoPipelinePermission] Security namespace or project not found."
        return
    }

    $tokenString = if ($Pipeline) { '{0}/{1}' -f $Project.id, $Pipeline.id } else { $Project.id }

    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $tokenString
    }

    Remove-AzDoPermission @params
}
