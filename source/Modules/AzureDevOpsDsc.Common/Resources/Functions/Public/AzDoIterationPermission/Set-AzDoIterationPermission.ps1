Function Set-AzDoIterationPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [string]$IterationPath,

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

    Write-Verbose "[Set-AzDoIterationPermission] Started."

    #
    # Security Namespace ID

    $SecurityNamespace = Get-CacheItem -Key 'Iteration' -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    if ($SecurityNamespace -eq $null)
    {
        Write-Error "[Set-AzDoIterationPermission] Security Namespace not found."
        return
    }

    if ($Project -eq $null)
    {
        Write-Error "[Set-AzDoIterationPermission] Project not found."
        return
    }

    #
    # Serialize the ACLs

    $token = $(($LookupResult.identifiers | ForEach-Object { "vstfs:///Classification/Node/{0}" -f $_ }) -join ':')

    # DescriptorACLList intentionally empty: 'merge=false' on the Set-AzDoPermission POST replaces the
    # ACL per-token (only tokens present in the request body are touched), so there is no need to
    # re-submit every other token's ACL. Merging in the whole namespace-wide 'LiveACLList' cache (as
    # this used to) meant the request body grew with every OTHER iteration node's cached ACL across
    # every project - confirmed via a live wire-level capture showing sibling sprint-node tokens
    # bundled into a single Sprint-1-only Set. Same bug/fix as
    # Set-AzDoSecurityNamespacePermission.ps1.
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
    # If the Iteration is not specified, this dictates that the permissions are for the Project.
    # Because of this we need to remove the ACE's that need to be removed prior to setting the new permissions.
    if (-not $IterationPath) {
        Write-Verbose "[Set-AzDoIterationPermission] Clearing ACEs."
        $params.ClearACEs = $true
        $params.DifferenceACLs = $LookupResult.DifferenceACLs
    }

    #
    # Set the Iteration Permissions

    Write-Verbose "[Set-AzDoIterationPermission] Parameters: $($params | ConvertTo-Json -Depth 5)"
    Set-AzDoPermission @params

}
