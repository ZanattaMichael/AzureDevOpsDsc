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

        [Parameter(Mandatory = $false)]
        [string]$BranchName,

        [Parameter(Mandatory = $false)]
        [string]$TagName,

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

    # Any refusal Get-AzDoGitPermission decided on (mutually-exclusive BranchName/TagName, or
    # BranchName/TagName without RepositoryName) comes back as status 'Error', which the base
    # class still routes to Set - so it has to be re-checked here via LookupResult.reason or it
    # would not hold.
    if ($LookupResult -and $LookupResult.reason -in @(
            'BranchName and TagName are mutually exclusive.',
            'BranchName/TagName requires RepositoryName.'))
    {
        Write-Warning "[Set-AzDoPermission] STOPPING: $($LookupResult.reason)"
        return
    }

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

    # BranchName/TagName are mutually exclusive - checked again defensively even though
    # Get-AzDoGitPermission already refuses this combination (see the LookupResult.reason check
    # above), since Set can also be called directly.
    $hasBranch = -not [String]::IsNullOrWhiteSpace($BranchName)
    $hasTag    = -not [String]::IsNullOrWhiteSpace($TagName)

    if ($hasBranch -and $hasTag)
    {
        Write-Warning "[Set-AzDoPermission] BranchName and TagName are mutually exclusive. STOPPING."
        return
    }

    $Repository = $null
    if ($hasBranch -or $hasTag -or $RepositoryName)
    {
        $Repository = Get-CacheItem -Key "$ProjectName\$RepositoryName" -Type 'LiveRepositories'
    }

    if (($hasBranch -or $hasTag) -and ($Repository -eq $null))
    {
        Write-Error "[Set-AzDoPermission] Repository not found."
        return
    }

    #
    # Serialize the ACLs

    # DescriptorACLList intentionally empty: 'merge=false' on the Set-AzDoPermission POST replaces the
    # ACL per-token, so there is no need to re-submit every other token's (repo's) ACL - same bug/fix
    # as Set-AzDoSecurityNamespacePermission.ps1.
    # Branch/tag tokens are matched exactly (one specific ref), so setting one branch's permission
    # never disturbs the repository's own ACL or any other branch's/tag's ACL - see
    # LocalizedDataAzSerializationPatten.GitBranch/.GitTag.
    $DescriptorMatchToken = if ($hasBranch) {
        $normalizedBranchName = Format-AzDoGitRefName -RefName $BranchName
        $LocalizedDataAzSerializationPatten.GitBranch -f $Repository.id, (ConvertTo-GitRefToken -RefName $normalizedBranchName)
    } elseif ($hasTag) {
        $normalizedTagName = Format-AzDoGitRefName -RefName $TagName
        $LocalizedDataAzSerializationPatten.GitTag -f $Repository.id, (ConvertTo-GitRefToken -RefName $normalizedTagName)
    } else {
        $LocalizedDataAzSerializationPatten.GitRepository -f $Project.id
    }

    $serializeACLParams = @{
        ReferenceACLs = $LookupResult.propertiesChanged
        DescriptorACLList = @()
        DescriptorMatchToken = $DescriptorMatchToken
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
