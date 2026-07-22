Function Set-AzDoAreaPermission
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

    Write-Verbose "[Set-AzDoAreaPermission] Started."

    #
    # Security Namespace ID

    $SecurityNamespace = Get-CacheItem -Key 'CSS' -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if ($SecurityNamespace -eq $null)
    {
        Write-Error "[Set-AzDoAreaPermission] Security Namespace not found."
        return
    }

    if ($Project -eq $null)
    {
        Write-Verbose "[Set-AzDoAreaPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $OrganizationName = Get-AzDoOrganizationName
        $Project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($Project) { Add-CacheItem -Key $ProjectName -Value $Project -Type 'LiveProjects' }
    }

    if ($Project -eq $null)
    {
        Write-Error "[Set-AzDoAreaPermission] Project not found: $ProjectName"
        return
    }

    #
    # Serialize the ACLs

    $token = $(($LookupResult.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

    # DescriptorACLList intentionally empty: 'merge=false' on the Set-AzDoPermission POST replaces the
    # ACL per-token (only tokens present in the request body are touched), so there is no need to
    # re-submit every other token's ACL. Merging in the whole namespace-wide 'LiveACLList' cache (as
    # this used to) meant the request body grew with every OTHER area node's cached ACL across every
    # project - same bug/fix as Set-AzDoSecurityNamespacePermission.ps1 / Set-AzDoIterationPermission.ps1.
    $serializeACLParams = @{
        ReferenceACLs = $LookupResult.propertiesChanged
        DescriptorACLList = @()
        DescriptorMatchToken = $token
    }

    $params = @{
        OrganizationName = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs = ConvertTo-ACLHashtable @serializeACLParams
    }

    #
    # If the Area is not specified, this dictates that the permissions are for the Project.
    # Because of this we need to remove the ACE's that need to be removed prior to setting the new permissions.
    if (-not $AreaPath) {
        Write-Verbose "[Set-AzDoAreaPermission] Clearing ACEs."
        $params.ClearACEs = $true
        $params.DifferenceACLs = $LookupResult.DifferenceACLs
    }

    #
    # Set the Area Permissions

    Write-Verbose "[Set-AzDoAreaPermission] Parameters: $($params | ConvertTo-Json -Depth 5)"
    Set-AzDoPermission @params

    # Invalidate the LiveACLList cache so the next Get re-fetches from the API.
    Remove-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'

}
