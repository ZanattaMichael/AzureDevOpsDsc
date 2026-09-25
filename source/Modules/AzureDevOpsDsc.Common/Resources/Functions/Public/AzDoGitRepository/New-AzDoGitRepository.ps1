<#
.SYNOPSIS
Creates a new Azure DevOps Git repository within a specified project.

.DESCRIPTION
The New-AzDoGitRepository function creates a new Git repository in an Azure DevOps project.

When 'SourceRepository' is supplied, the repository is seeded at creation time as either a fork of
an existing Azure DevOps repository (using the native 'parentRepository' support on the create
call) or an import from an external Git URL (via the asynchronous Import Requests API, polled to
completion) - see 'SourceType'. This only ever happens here, at creation time: it is never repeated
by Set-AzDoGitRepository, and a failed import is surfaced as an error rather than left as a
silently-empty repository.

.PARAMETER ProjectName
The name of the Azure DevOps project where the new repository will be created.

.PARAMETER RepositoryName
The name of the new Git repository to be created.

.PARAMETER SourceRepository
(Optional) Seeds the repository at creation time. Its meaning depends on 'SourceType': a Git URL
(or SSH remote) for an import, or 'Project/Repo' (or just 'Repo' for a repository in this project)
for a fork.

.PARAMETER SourceType
(Optional) 'Import' or 'Fork'. When omitted and 'SourceRepository' is set, it is inferred: a URL or
an SSH remote (e.g. 'git@host:owner/repo.git') defaults to 'Import', anything else to 'Fork'.

.PARAMETER ImportServiceConnectionName
(Optional) The name of a generic Git service connection (in this project) holding the credentials
needed to import from a private 'SourceRepository' URL. Only used when importing.

.PARAMETER IsDisabled
(Optional) When $true, disables the repository once it (and any import) has finished being created.

.PARAMETER LookupResult
(Optional) A hashtable to store lookup results.

.PARAMETER Ensure
(Optional) Specifies whether to ensure the repository exists or does not exist.

.PARAMETER Force
(Optional) Forces the creation of the repository even if it already exists.

.EXAMPLE
PS> New-AzDoGitRepository -ProjectName "MyProject" -RepositoryName "MyRepo"

Creates a new, empty Git repository named "MyRepo" in the "MyProject" Azure DevOps project.

.EXAMPLE
PS> New-AzDoGitRepository -ProjectName "MyProject" -RepositoryName "MyRepo" -SourceRepository "https://github.com/MyUser/MyRepo.git"

Creates "MyRepo" and imports the contents of the public GitHub repository at that URL.

.EXAMPLE
PS> New-AzDoGitRepository -ProjectName "MyProject" -RepositoryName "MyRepo" -SourceRepository "TemplateProject/TemplateRepo" -SourceType Fork

Creates "MyRepo" as a fork of "TemplateRepo" in the "TemplateProject" project.

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
        [Alias('SourceKind')]
        [System.String]$SourceType,

        [Parameter()]
        [Alias('ServiceConnection')]
        [System.String]$ImportServiceConnectionName,

        [Parameter()]
        [System.Boolean]$IsDisabled = $false,

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
    $ApiUri  = 'https://dev.azure.com/{0}/' -f $OrganizationName
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

    # Resolve how (if at all) the repository should be seeded. This only ever happens here, at
    # creation time - 'SourceRepository'/'SourceType'/'ImportServiceConnectionName' are listed in
    # the class's 'GetDscResourcePropertyNamesWithNoSetSupport()' and are never passed to Set().
    $effectiveSourceType = $null
    $parentRepository    = $null

    if (![System.String]::IsNullOrWhiteSpace($SourceRepository))
    {
        if (![System.String]::IsNullOrWhiteSpace($SourceType))
        {
            $effectiveSourceType = $SourceType
        }
        else
        {
            # A URL (any scheme) or an SSH remote (e.g. 'git@host:owner/repo.git') is an import;
            # anything else - a bare repository name, or 'Project/Repo' - is a fork of an existing
            # Azure DevOps repository.
            $looksLikeUrl = ($SourceRepository -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') -or ($SourceRepository -match '^[^@\s/]+@[^:\s]+:')
            $effectiveSourceType = if ($looksLikeUrl) { 'Import' } else { 'Fork' }
        }

        Write-Verbose "[New-AzDoGitRepository] SourceRepository '$SourceRepository' resolved to SourceType '$effectiveSourceType'."
    }

    if ($effectiveSourceType -eq 'Fork')
    {
        # 'SourceRepository' is 'Project/Repo', or just 'Repo' for a repository in this project.
        if ($SourceRepository -match '^(?<project>[^/]+)/(?<repo>.+)$')
        {
            $sourceProjectName = $Matches.project
            $sourceRepoName    = $Matches.repo
        }
        else
        {
            $sourceProjectName = $ProjectName
            $sourceRepoName    = $SourceRepository
        }

        $sourceProject = if ($sourceProjectName -eq $ProjectName) { $project } else { Resolve-AzDoProject -ProjectName $sourceProjectName }

        if ($null -eq $sourceProject)
        {
            Write-Error "[New-AzDoGitRepository] Fork source project '$sourceProjectName' not found. Skipping change."
            return
        }

        $sourceRepo = Get-CacheItem -Key "$sourceProjectName\$sourceRepoName" -Type 'LiveRepositories'
        if ($null -eq $sourceRepo)
        {
            $allSourceRepos = List-DevOpsGitRepository -OrganizationName $OrganizationName -ProjectName $sourceProjectName
            $sourceRepo     = $allSourceRepos | Where-Object { $_.name -eq $sourceRepoName } | Select-Object -First 1
        }

        if ($null -eq $sourceRepo)
        {
            Write-Error "[New-AzDoGitRepository] Fork source repository '$sourceRepoName' not found in project '$sourceProjectName'. Skipping change."
            return
        }

        $parentRepository = @{
            id      = $sourceRepo.id
            project = @{ id = $sourceProject.id }
        }
    }

    # Define parameters for creating the repository
    $params = @{
        ApiUri         = $ApiUri
        Project        = $project
        RepositoryName = $RepositoryName
    }

    if ($parentRepository)
    {
        $params.ParentRepository = $parentRepository
    }

    # Create the (possibly forked) repository
    $value = New-GitRepository @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoGitRepository] New-GitRepository returned null for repository '$RepositoryName' in project '$ProjectName'. Check authentication token and organization settings."
        return
    }

    if ($effectiveSourceType -eq 'Import')
    {
        $serviceEndpointId = $null

        if (![System.String]::IsNullOrWhiteSpace($ImportServiceConnectionName))
        {
            $serviceConnection = Get-CacheItem -Key "$ProjectName\$ImportServiceConnectionName" -Type 'LiveServiceConnections'
            if ($null -eq $serviceConnection)
            {
                $allServiceConnections = List-DevOpsServiceConnections -ApiUri $ApiUri -ProjectName $ProjectName
                $serviceConnection     = $allServiceConnections | Where-Object { $_.name -eq $ImportServiceConnectionName } | Select-Object -First 1
            }

            if ($null -eq $serviceConnection)
            {
                Write-Error "[New-AzDoGitRepository] Import service connection '$ImportServiceConnectionName' not found in project '$ProjectName'. Repository '$RepositoryName' was created empty."
                return
            }

            $serviceEndpointId = $serviceConnection.id
        }

        Write-Verbose "[New-AzDoGitRepository] Importing '$SourceRepository' into repository '$RepositoryName'."

        $importParams = @{
            ApiUri     = $ApiUri
            Project    = $project
            Repository = $value
            SourceUrl  = $SourceRepository
        }
        if ($serviceEndpointId) { $importParams.ServiceEndpointId = $serviceEndpointId }

        $importRequest = New-GitImportRequest @importParams

        if ($null -eq $importRequest)
        {
            Write-Error "[New-AzDoGitRepository] New-GitImportRequest returned null for repository '$RepositoryName'. Repository was created empty - import was not started."
            return
        }

        $null = Wait-DevOpsGitImportRequest -ApiUri $ApiUri -Project $project -Repository $value -ImportRequestId $importRequest.importRequestId
    }

    if ($IsDisabled)
    {
        Write-Verbose "[New-AzDoGitRepository] Disabling repository '$RepositoryName' as requested."
        $disabledRepo = Set-GitRepository -ApiUri $ApiUri -Project $project -Repository $value -IsDisabled $true
        if ($disabledRepo) { $value = $disabledRepo }
    }

    # Add the repository to the LiveRepositories cache and write to verbose log
    Add-CacheItem -Key "$ProjectName\$RepositoryName" -Value $value -Type 'LiveRepositories'
    Export-CacheObject -CacheType 'LiveRepositories' -Content $AzDoLiveRepositories
    Refresh-CacheObject -CacheType 'LiveRepositories'
    Write-Verbose "[New-AzDoGitRepository] Added new group to LiveGroups cache with key: '$($value.Name)'"

}
