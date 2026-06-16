<#
.SYNOPSIS
Retrieves the Git repository permissions for a specified Azure DevOps project and repository.

.DESCRIPTION
The Get-AzDoGitPermission function retrieves the Git repository permissions for a specified Azure DevOps project and repository.
It performs a lookup within the cache for the repository and retrieves the Access Control List (ACL) for the repository.
The function then compares the retrieved ACLs with the provided permissions and returns the result.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER RepositoryName
The name of the Git repository within the Azure DevOps project.

.PARAMETER isInherited
A boolean value indicating whether the permissions are inherited.

.PARAMETER Permissions
An optional hashtable array of permissions to compare against the retrieved ACLs.

.PARAMETER LookupResult
An optional hashtable to store the lookup result.

.PARAMETER Ensure
An optional parameter to specify the desired state of the permissions.

.PARAMETER Force
A switch parameter to force the operation.

.EXAMPLE
Get-AzDoGitPermission -ProjectName "MyProject" -RepositoryName "MyRepo" -isInherited $true

This example retrieves the Git repository permissions for the "MyRepo" repository in the "MyProject" Azure DevOps project,
considering inherited permissions.

.NOTES
The function relies on cached items for the repository and security namespace.
It uses helper functions like Get-CacheItem, Get-DevOpsACL, ConvertTo-FormattedACL, ConvertTo-ACL, and Test-ACLListforChanges.

#>

Function Get-AzDoGitPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoGitPermission] Started."

    # Define the Descriptor Type and Organization Name
    $SecurityNamespace = 'Git Repositories'
    $OrganizationName = (Get-AzDoOrganizationName)

    Write-Verbose "[Get-AzDoGitPermission] Security Namespace: $SecurityNamespace"
    Write-Verbose "[Get-AzDoGitPermission] Organization Name: $OrganizationName"
    Write-Verbose "[Get-AzDoGitPermission] Project Name: $ProjectName"


    if ([String]::IsNullOrEmpty($RepositoryName)) {

        Write-Warning "[Get-AzDoGitPermission] RepositoryName not specified. Defaulting to top-level Project permissions"
        $RepositoryName = $null

    } else {
        Write-Verbose "[Get-AzDoGitPermission] Repository Name: $RepositoryName"
    }

    #
    # Construct a hashtable detailing the group

    $getGroupResult = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @()
        project = $ProjectName
        repositoryName = $RepositoryName
        status = $null
        reason = $null
    }

    Write-Verbose "[Get-AzDoGitPermission] Group result hashtable constructed."
    Write-Verbose "[Get-AzDoGitPermission] Performing lookup of permissions for the repository."

    # Define the ACL List
    $ACLList = [System.Collections.Generic.List[Hashtable]]::new()

    # Perform a Lookup within the Cache for the Project, with live fallback
    $projectCache = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $projectCache)
    {
        Write-Verbose "[Get-AzDoGitPermission] Project '$ProjectName' not in cache — falling back to live API lookup."
        $projectCache = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($projectCache) { Add-CacheItem -Key $ProjectName -Value $projectCache -Type 'LiveProjects' }
    }

    # Test if the Project was found
    if (-not $projectCache)
    {
        Write-Warning "[Get-AzDoGitPermission] Project not found: $ProjectName"
        $getGroupResult.status = [DSCGetSummaryState]::Error
        $getGroupResult.reason = "Project not found: $ProjectName"

        return $getGroupResult
    }

    # Test if the RepositoryName was specified
    if ($RepositoryName) {

        #
        Write-Verbose "[Get-AzDoGitPermission] Repository Name: $RepositoryName is not null."

        #
        # Perform a Lookup within the Cache for the Repository
        $repoCacheKey    = '{0}\{1}' -f $ProjectName, $RepositoryName
        $repositoryCache = Get-CacheItem -Key $repoCacheKey -Type 'LiveRepositories'

        if (-not $repositoryCache)
        {
            Write-Verbose "[Get-AzDoGitPermission] Repository '$RepositoryName' not in cache — falling back to live API lookup."
            $allRepos        = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/$ProjectName/_apis/git/repositories?api-version=7.1-preview.1" -Method Get
            $repositoryCache = $allRepos.value | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
            if ($repositoryCache) { Add-CacheItem -Key $repoCacheKey -Value $repositoryCache -Type 'LiveRepositories' }
        }

        # Test if the Repository was found, however only if the ProjectName was specified
        if (-not $repositoryCache)
        {
            Write-Warning "[Get-AzDoGitPermission] Repository not found: $RepositoryName"
            $getGroupResult.status = [DSCGetSummaryState]::NotFound
            return $getGroupResult
        }

    }

    #
    # Perform Lookup of the Permissions

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    Write-Verbose "[Get-AzDoGitPermission] Retrieved namespace: $($namespace.namespaceId)"

    # Add to the ACL Lookup Params
    $getGroupResult.namespace = $namespace

    # Token-scope the ACL fetch to this repository's (or the project's) Git token instead of pulling
    # every ACL in the namespace. Fall back to the full-namespace fetch if the scoped query returns
    # nothing, so behaviour is never worse than the previous full scan.
    $aclToken = if ($RepositoryName) { 'repoV2/{0}/{1}' -f $projectCache.id, $repositoryCache.id } else { 'repoV2/{0}' -f $projectCache.id }
    $ACLLookupParams = @{
        OrganizationName        = $OrganizationName
        SecurityDescriptorId    = $namespace.namespaceId
        Token                   = $aclToken
    }

    # Get the ACL List and format the ACLS
    Write-Verbose "[Get-AzDoGitPermission] ACL Lookup Params: $($ACLLookupParams | Out-String)"

    # Get the ACLs for the Repository
    $DevOpsACLs = Get-DevOpsACL @ACLLookupParams
    if ($null -eq $DevOpsACLs) { $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId }

    # Test if the ACLs were found
    if ($DevOpsACLs -eq $null)
    {
        Write-Error "[Get-AzDoGitPermission] No ACLs were found within the Security Namespace."
        $getGroupResult.status = [DSCGetSummaryState]::Error
        $getGroupResult.reason = "No ACLs were found within the Security Namespace."
        return $getGroupResult
    }

    # Convert the ACLs to a formatted ACL
    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    # Test if the ACLs were found
    if ($DifferenceACLs -eq $null)
    {
        Write-Warning "[Get-AzDoGitPermission] No ACLs found for the repository."
        $getGroupResult.status = [DSCGetSummaryState]::NotFound
        return $getGroupResult
    }

    # Filter the ACLs for the Repository
    # If the Repository is not specified, return the GitProject ACLs
    if (-not $RepositoryName) {
        # Filter the ACLs for the top-level GitProject
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'GitProject') -and ($_.Token.ProjectId -eq $projectCache.id)
        }
    } else {
        # Filter the ACLs for the GitRepository
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'GitRepository') -and ($_.Token.RepoId -eq $repositoryCache.id)
        }
    }

    Write-Verbose "[Get-AzDoGitPermission] ACL List retrieved and formatted."

    #
    # Convert the Permissions into an ACL Token

    $params = @{
        Permissions         = $Permissions
        SecurityNamespace   = $SecurityNamespace
        isInherited         = $isInherited
        OrganizationName    = $OrganizationName
        TokenName           = $(
                                if (-not $RepositoryName) {
                                    'repoV2\{0}' -f $ProjectName
                                } else {
                                    '[{0}]\{1}' -f $ProjectName, $RepositoryName
                                })
    }

    # Convert the Permissions to an ACL Token
    $ReferenceACLs = ConvertTo-ACL @params | Where-Object { $_.token.Type -ne 'GitUnknown' }

    # Compare the Reference ACLs to the Difference ACLs
    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs
    $getGroupResult.propertiesChanged = $compareResult.propertiesChanged
    $getGroupResult.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $getGroupResult.reason = $compareResult.reason

    Write-Verbose "[Get-AzDoGitPermission] ACL Token converted."
    Write-Verbose "[Get-AzDoGitPermission] ACL Token Comparison Result: $($getGroupResult.status)"

    # Export the ACL List to a file
    $getGroupResult.ReferenceACLs = $ReferenceACLs
    $getGroupResult.DifferenceACLs = $DifferenceACLs

    # Write
    Write-Verbose "[Get-AzDoGitPermission] Result Status: $($getGroupResult.status)"
    Write-Verbose "[Get-AzDoGitPermission] Returning Group Result."

    # Return the Group Result
    return $getGroupResult

}

