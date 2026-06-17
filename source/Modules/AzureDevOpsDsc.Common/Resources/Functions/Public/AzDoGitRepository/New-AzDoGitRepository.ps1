<#
.SYNOPSIS
Creates a new Azure DevOps Git repository within a specified project.

.DESCRIPTION
The New-AzDoGitRepository function creates a new Git repository in an Azure DevOps project.
It uses the provided project name and repository name to create the repository.
Optionally, a source repository can be specified to initialize the new repository.

.PARAMETER ProjectName
The name of the Azure DevOps project where the new repository will be created.

.PARAMETER RepositoryName
The name of the new Git repository to be created.

.PARAMETER SourceRepository
(Optional) The name of the source repository to initialize the new repository.

.PARAMETER LookupResult
(Optional) A hashtable to store lookup results.

.PARAMETER Ensure
(Optional) Specifies whether to ensure the repository exists or does not exist.

.PARAMETER Force
(Optional) Forces the creation of the repository even if it already exists.

.EXAMPLE
PS> New-AzDoGitRepository -ProjectName "MyProject" -RepositoryName "MyRepo"

Creates a new Git repository named "MyRepo" in the "MyProject" Azure DevOps project.

.EXAMPLE
PS> New-AzDoGitRepository -ProjectName "MyProject" -RepositoryName "MyRepo" -SourceRepository "TemplateRepo"

Creates a new Git repository named "MyRepo" in the "MyProject" Azure DevOps project, initialized with the contents of "TemplateRepo".

.NOTES
This function requires the Azure DevOps organization name to be set in the global variable (Get-AzDoOrganizationName).
#>

Function New-AzDoGitRepository
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

    Write-Verbose "[New-AzDoGitRepository] Creating new repository '$($RepositoryName)' in project '$($ProjectName)'"

    $OrganizationName = Get-AzDoOrganizationName
    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'

    # If not in cache, fall back to a live API lookup
    if ($null -eq $project)
    {
        Write-Verbose "[New-AzDoGitRepository] Project '$ProjectName' not in cache — falling back to live API lookup."
        $project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($project) { Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects' }
    }

    if ($null -eq $project)
    {
        Write-Error "[New-AzDoGitRepository] Project '$ProjectName' not found. Skipping change."
        return
    }

    # Define parameters for creating a new DevOps group
    $params = @{
        ApiUri = 'https://dev.azure.com/{0}/' -f $OrganizationName
        Project = $project
        RepositoryName = $RepositoryName
        SourceRepository = $SourceRepository
    }


    # Create a new repository
    $value = New-GitRepository @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoGitRepository] New-GitRepository returned null for repository '$RepositoryName' in project '$ProjectName'. Check authentication token and organization settings."
        return
    }

    # Add the repository to the LiveRepositories cache and write to verbose log
    Add-CacheItem -Key "$ProjectName\$RepositoryName" -Value $value -Type 'LiveRepositories'
    Export-CacheObject -CacheType 'LiveRepositories' -Content $AzDoLiveRepositories
    Refresh-CacheObject -CacheType 'LiveRepositories'
    Write-Verbose "[New-AzDoGitRepository] Added new group to LiveGroups cache with key: '$($value.Name)'"

}
