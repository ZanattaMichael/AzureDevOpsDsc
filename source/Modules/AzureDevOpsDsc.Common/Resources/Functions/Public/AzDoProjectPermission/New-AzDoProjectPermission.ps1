Function New-AzDoProjectPermission
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

    Write-Verbose "[New-AzDoProjectPermission] Started."

    $OrganizationName  = Get-AzDoOrganizationName
    $SecurityNamespace = Get-CacheItem -Key 'Project' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if (-not $Project)
    {
        Write-Verbose "[New-AzDoProjectPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $Project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($Project) { Add-CacheItem -Key $ProjectName -Value $Project -Type 'LiveProjects' }
    }

    if ((-not $SecurityNamespace) -or (-not $Project))
    {
        Write-Error "[New-AzDoProjectPermission] Security namespace or project not found."
        return
    }

    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = ($LocalizedDataAzSerializationPatten.ProjectPermission -f $Project.id)
    }

    $params = @{
        OrganizationName    = $OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
    }

    Set-AzDoPermission @params
}
