<#
.SYNOPSIS
Creates an Azure DevOps YAML pipeline.

.DESCRIPTION
Creates a pipeline backed by an Azure Repos ('TfsGit') repository, or by an external
(GitHub/GitHub Enterprise/Bitbucket) repository reached through a service connection.

The Pipelines API used to create the pipeline does not apply a default branch (the pipeline takes
the repository's, which an empty repository does not have) and has no concept of variables at all.
Both are applied afterwards by writing the new pipeline's build definition back through
'Set-DevOpsPipeline' and 'Set-DevOpsPipelineVariables'. The created pipeline is cached first, so a
failure in either follow-up call is thrown with the pipeline still known to the next 'Get'.

.PARAMETER ProjectName
The Azure DevOps project name.

.PARAMETER PipelineName
The name of the pipeline.

.PARAMETER RepositoryName
The repository that contains the YAML file. An Azure Repos repository name, or 'owner/repo' for
GitHub/GitHub Enterprise/Bitbucket.

.PARAMETER YamlPath
The path to the YAML pipeline definition file.

.PARAMETER FolderPath
The folder path under which the pipeline is organised.

.PARAMETER DefaultBranch
The default branch for the pipeline.

.PARAMETER RepositoryType
The type of repository backing the pipeline. 'TfsGit', 'GitHub', 'GitHubEnterprise' or
'Bitbucket'.

.PARAMETER ServiceConnectionName
The service connection used to reach the repository. Required when 'RepositoryType' is not
'TfsGit'.

.PARAMETER Variables
Pipeline variables to manage, as an array of hashtables shaped
'@{ Name; Value; IsSecret; AllowOverride }'.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoPipeline -ProjectName 'Contoso' -PipelineName 'CI' -RepositoryName 'Contoso' -YamlPath 'azure-pipelines.yml'
#>
Function New-AzDoPipeline
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$PipelineName,
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$YamlPath,
        [Parameter()][string]$FolderPath = '\',
        [Parameter()][string]$DefaultBranch = 'main',
        [Parameter()][ValidateSet('TfsGit', 'GitHub', 'GitHubEnterprise', 'Bitbucket')][string]$RepositoryType = 'TfsGit',
        [Parameter()][string]$ServiceConnectionName,
        [Parameter()][Hashtable[]]$Variables,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoPipeline] Creating pipeline '$PipelineName'."

    # 'Get' returning 'Error' still routes here (see AzDevOpsDscResourceBase.GetDscRequiredAction()),
    # so the same guard that 'Get-AzDoPipeline' applies has to be repeated here.
    if ($RepositoryType -ne 'TfsGit' -and [String]::IsNullOrWhiteSpace($ServiceConnectionName))
    {
        Write-Error "[New-AzDoPipeline] 'ServiceConnectionName' is required when 'RepositoryType' is '$RepositoryType'."
        return
    }

    $project = Resolve-AzDoProject -ProjectName $ProjectName

    if (-not $project)
    {
        Write-Error "[New-AzDoPipeline] Project '$ProjectName' not found."
        return
    }

    $OrgName = Get-AzDoOrganizationName
    $ApiUri  = 'https://dev.azure.com/{0}/' -f $OrgName

    $repositoryId        = $null
    $serviceConnectionId = $null
    $repository          = $null
    $connection          = $null

    if ($RepositoryType -eq 'TfsGit')
    {
        $repository = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories'
        if (-not $repository)
        {
            # Repository may have been created after the cache was built at init — fall back to a live lookup.
            Write-Verbose "[New-AzDoPipeline] Repository '$RepositoryName' not in cache — falling back to live API lookup."
            $allRepos   = List-DevOpsGitRepository -OrganizationName $OrgName -ProjectName $ProjectName
            $repository = $allRepos | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
        }
        $repositoryId = if ($repository) { $repository.id } else { $null }
    }
    else
    {
        $connection = Resolve-AzDoServiceConnection -ProjectName $ProjectName -ConnectionName $ServiceConnectionName
        if (-not $connection)
        {
            Write-Error "[New-AzDoPipeline] Service connection '$ServiceConnectionName' not found in project '$ProjectName'."
            return
        }
        $serviceConnectionId = $connection.id
    }

    $params = @{
        ApiUri              = $ApiUri
        ProjectName         = $ProjectName
        PipelineName        = $PipelineName
        FolderPath          = $FolderPath
        YamlFilePath        = $YamlPath
        RepositoryId        = $repositoryId
        RepositoryName      = $RepositoryName
        RepositoryType      = Convert-AzDoPipelineRepositoryType -RepositoryType $RepositoryType
        ServiceConnectionId = $serviceConnectionId
        DefaultBranch       = 'refs/heads/{0}' -f $DefaultBranch
    }

    $value = New-DevOpsPipeline @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoPipeline] New-DevOpsPipeline returned null. Check authentication token and organization settings."
        return
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Value $value -Type 'LivePipelines'
    Export-CacheObject -CacheType 'LivePipelines' -Content $AzDoLivePipelines
    Refresh-CacheObject -CacheType 'LivePipelines'

    Write-Verbose "[New-AzDoPipeline] Applying the default branch '$DefaultBranch' to pipeline '$PipelineName'."
    $setParams = @{
        ApiUri              = $ApiUri
        ProjectName         = $ProjectName
        PipelineId          = $value.id
        PipelineName        = $PipelineName
        FolderPath          = $FolderPath
        YamlFilePath        = $YamlPath
        RepositoryId        = $repositoryId
        RepositoryName      = $RepositoryName
        RepositoryType      = $RepositoryType
        RepositoryUrl       = Get-AzDoPipelineRepositoryUrl -RepositoryType $RepositoryType -RepositoryName $RepositoryName -Repository $repository -ServiceConnection $connection
        ServiceConnectionId = $serviceConnectionId
        DefaultBranch       = 'refs/heads/{0}' -f $DefaultBranch
    }
    Set-DevOpsPipeline @setParams | Out-Null

    if ($Variables -and $Variables.Count -gt 0)
    {
        Write-Verbose "[New-AzDoPipeline] Writing $($Variables.Count) variable(s) onto pipeline '$PipelineName'."
        Set-DevOpsPipelineVariables -ApiUri $ApiUri -ProjectName $ProjectName -DefinitionId $value.id -Variables $Variables | Out-Null
    }

    Write-Verbose "[New-AzDoPipeline] Pipeline '$PipelineName' created."
}
