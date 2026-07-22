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

    $OrganizationName  = Get-AzDoOrganizationName
    $SecurityNamespace = Get-CacheItem -Key 'Library' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if (-not $Project)
    {
        Write-Verbose "[Set-AzDoVariableGroupPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $Project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($Project) { Add-CacheItem -Key $ProjectName -Value $Project -Type 'LiveProjects' }
    }

    if ((-not $SecurityNamespace) -or (-not $Project)) { Write-Error "[Set-AzDoVariableGroupPermission] Cache miss."; return }

    # DescriptorACLList intentionally empty: 'merge=false' on the Set-AzDoPermission POST replaces the
    # ACL per-token, so there is no need to re-submit every other token's (variable group's) ACL - same
    # bug/fix as Set-AzDoSecurityNamespacePermission.ps1.
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = @()
        DescriptorMatchToken = ($LocalizedDataAzSerializationPatten.LibraryPermission -f $Project.id)
    }

    $params = @{
        OrganizationName    = $OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
        ClearACEs           = $true
        DifferenceACLs      = $LookupResult.DifferenceACLs
    }

    Set-AzDoPermission @params
}
