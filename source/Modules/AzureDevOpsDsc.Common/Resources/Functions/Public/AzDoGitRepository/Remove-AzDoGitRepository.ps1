<#
.SYNOPSIS
Removes a Git repository from an Azure DevOps project.

.DESCRIPTION
The Remove-AzDoGitRepository function removes a specified Git repository from a given Azure DevOps project.
It checks the existence of the project and repository in the LiveProjects and LiveRepositories cache before attempting the removal.

.PARAMETER ProjectName
The name of the Azure DevOps project containing the repository to be removed.

.PARAMETER RepositoryName
The name of the repository to be removed.

.PARAMETER SourceRepository
An optional parameter specifying the source repository.

.PARAMETER LookupResult
An optional hashtable parameter for lookup results.

.PARAMETER Ensure
An optional parameter to ensure the state of the repository.

.PARAMETER Force
A switch parameter to force the removal of the repository.

.EXAMPLE
Remove-AzDoGitRepository -ProjectName "MyProject" -RepositoryName "MyRepo" -Force

.NOTES
This function relies on the existence of certain global variables and cache items.
Ensure that the necessary cache items and global variables are properly set before invoking this function.
#>
Function Remove-AzDoGitRepository
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Alias('Repository')]
        [System.String]$RepositoryName,

        [Parameter()]
        [Alias('Source')]
        [System.String]$SourceRepository,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Write-Verbose "[Remove-AzDoGitRepository] Removing repository '$($RepositoryName)' in project '$($ProjectName)'"

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if ($null -eq $project)
    {
        Write-Error "[Remove-AzDoGitRepository] Project '$($ProjectName)' not found. Skipping change."
        return
    }

    $repository = Get-CacheItem -Key "$ProjectName\$RepositoryName" -Type 'LiveRepositories'
    if ($null -eq $repository)
    {
        # Repository may have been created after the cache was built at init — fall back to a live lookup.
        $allRepos   = List-DevOpsGitRepository -OrganizationName (Get-AzDoOrganizationName) -ProjectName $ProjectName
        $repository = $allRepos | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
    }

    if ($null -eq $repository)
    {
        # Already absent — nothing to remove (desired state achieved).
        Write-Verbose "[Remove-AzDoGitRepository] Repository '$RepositoryName' not found; already absent."
        return
    }

    # Define parameters for removing the repository
    $params = @{
        ApiUri     = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        Project    = $project
        Repository = $repository
    }

    # Create a new repository
    $value = Remove-GitRepository @params

    # Add the repository to the LiveRepositories cache and write to verbose log
    Remove-CacheItem -Key "$ProjectName\$RepositoryName" -Type 'LiveRepositories'
    Export-CacheObject -CacheType 'LiveRepositories' -Content $AzDoLiveRepositories
    Write-Verbose "[Remove-AzDoGitRepository] Added new group to LiveGroups cache with key: '$($value.Name)'"

}
