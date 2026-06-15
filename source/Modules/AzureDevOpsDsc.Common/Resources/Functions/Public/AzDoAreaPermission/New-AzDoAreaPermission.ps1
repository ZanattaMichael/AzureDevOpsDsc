Function New-AzDoAreaPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [string]$AreaPath,

        [Parameter(Mandatory = $true)]
        [bool]$isInherited,

        [Parameter()]
        [HashTable[]]$Permissions,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Write-Verbose "[New-AzDoAreaPermission] Started."

    #
    # Security Namespace ID

    $SecurityNamespace = Get-CacheItem -Key 'CSS' -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if ($null -eq $SecurityNamespace)
    {
        Write-Warning "[New-AzDoAreaPermission] Security Namespace not found."
        return
    }

    if ($null -eq $Project)
    {
        Write-Verbose "[New-AzDoAreaPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $OrganizationName = Get-AzDoOrganizationName
        $Project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($Project) { Add-CacheItem -Key $ProjectName -Value $Project -Type 'LiveProjects' }
    }

    if ($null -eq $Project)
    {
        Write-Warning "[New-AzDoAreaPermission] Project not found: $ProjectName"
        return
    }

    #
    # Serialize the ACLs

    $token = $(($LookupResult.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

    $serializeACLParams = @{
        ReferenceACLs = $LookupResult.propertiesChanged
        DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = $token
    }

    $params = @{
        OrganizationName = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs = ConvertTo-ACLHashtable @serializeACLParams
    }

    Write-Verbose "[New-AzDoAreaPermission] Setting Area Path Permissions for $ProjectName - $AreaPath"

    Set-AzDoPermission @params

    # Invalidate the LiveACLList cache so the next Get re-fetches from the API.
    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'

}
