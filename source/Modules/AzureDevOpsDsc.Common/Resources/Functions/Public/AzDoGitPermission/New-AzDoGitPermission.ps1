<#
.SYNOPSIS
Creates new Git repository permissions in Azure DevOps.

.DESCRIPTION
The New-AzDoGitPermission function sets up new permissions for a specified Git repository within a given project in Azure DevOps. It uses cached security namespace and project information to serialize ACLs and apply the permissions.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER RepositoryName
The name of the Git repository within the Azure DevOps project.

.PARAMETER isInherited
Indicates whether the permissions are inherited.

.PARAMETER BranchName
Optional. Targets a single branch's ACL instead of the repository's own ACL. Requires
RepositoryName and is mutually exclusive with TagName.

.PARAMETER TagName
Optional. Targets a single tag's ACL instead of the repository's own ACL. Requires RepositoryName
and is mutually exclusive with BranchName.

.PARAMETER Permissions
A hashtable array of permissions to be applied.

.PARAMETER LookupResult
A hashtable containing the lookup result properties.

.PARAMETER Ensure
Specifies whether to ensure the permissions are set.

.PARAMETER Force
A switch parameter to force the operation.

.EXAMPLE
New-AzDoGitPermission -ProjectName "MyProject" -RepositoryName "MyRepo" -isInherited $true -Permissions $permissions -LookupResult $lookupResult -Ensure "Present" -Force

.NOTES
This function relies on cached items for security namespace and project information. Ensure that the cache is populated before calling this function.
#>
Function New-AzDoGitPermission
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

    Write-Verbose "[New-AzDoGitPermission] Started."

    #
    # Test if the Repository is specified
    if ([String]::IsNullOrEmpty($RepositoryName))
    {
        Write-Warning "[New-AzDoGitPermission] Repository Name not specified. Defaulting to top-level Project permissions."
        Write-Warning "[New-AzDoGitPermission] STOPPING. It is not possible add permissions to a top-level Project."
        return
    }

    # BranchName and TagName are mutually exclusive - 'refs/heads' and 'refs/tags' are different
    # tokens, so there is no single ACL to add permissions to when both are given.
    $hasBranch = -not [String]::IsNullOrWhiteSpace($BranchName)
    $hasTag    = -not [String]::IsNullOrWhiteSpace($TagName)

    if ($hasBranch -and $hasTag)
    {
        Write-Warning "[New-AzDoGitPermission] BranchName and TagName are mutually exclusive. STOPPING."
        return
    }

    #
    # Security Namespace ID

    $SecurityNamespace = Get-CacheItem -Key 'Git Repositories' -Type 'SecurityNamespaces'
    $Project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $Repository = Get-CacheItem -Key "$ProjectName\$RepositoryName" -Type 'LiveRepositories'

    if (($null -eq $SecurityNamespace) -or ($null -eq $Project) -or ($null -eq $Repository))
    {
        Write-Warning "[New-AzDoGitPermission] Security Namespace, Project or Repository not found."
        return
    }

    #
    # Serialize the ACLs

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
        DescriptorACLList = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = $DescriptorMatchToken
    }

    $params = @{
        OrganizationName = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs = ConvertTo-ACLHashtable @serializeACLParams
    }

    #
    # Set the Git Repository Permissions

    Set-AzDoPermission @params

}
