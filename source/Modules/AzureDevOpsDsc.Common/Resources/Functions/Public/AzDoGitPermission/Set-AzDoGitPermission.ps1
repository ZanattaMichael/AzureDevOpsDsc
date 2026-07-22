Function Set-AzDoGitPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [string]$RepositoryName,

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

    Write-Verbose "[Set-AzDoPermission] Started."

    #
    # Security Namespace ID

    $SecurityNamespace = Get-CacheItem -Key 'Git Repositories' -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if ($SecurityNamespace -eq $null)
    {
        Write-Error "[Set-AzDoPermission] Security Namespace not found."
        return
    }

    if ($Project -eq $null)
    {
        Write-Error "[Set-AzDoPermission] Project not found."
        return
    }

    #
    # Serialize the ACLs

    # DescriptorACLList intentionally empty: 'merge=false' on the Set-AzDoPermission POST replaces the
    # ACL per-token, so there is no need to re-submit every other token's (repo's) ACL - same bug/fix
    # as Set-AzDoSecurityNamespacePermission.ps1.
    $serializeACLParams = @{
        ReferenceACLs = $LookupResult.propertiesChanged
        DescriptorACLList = @()
        DescriptorMatchToken = ($LocalizedDataAzSerializationPatten.GitRepository -f $Project.id)
    }

    $params = @{
        OrganizationName = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs = ConvertTo-ACLHashtable @serializeACLParams
    }

    #
    # If the Repository is not specified, this dictates that the permissions are for the Project.
    # Because of this we need to remove the ACE's that need to be removed prior to setting the new permissions.
    if (-not $RepositoryName) {
        Write-Verbose "[Set-AzDoPermission] Clearing ACEs."
        $params.ClearACEs = $true
        $params.DifferenceACLs = $LookupResult.DifferenceACLs
    }

    #
    # Set the Git Repository Permissions

    Write-Verbose "[Set-AzDoPermission] Parameters: $($params | ConvertTo-Json -Depth 5)"
    Set-AzDoPermission @params

}
