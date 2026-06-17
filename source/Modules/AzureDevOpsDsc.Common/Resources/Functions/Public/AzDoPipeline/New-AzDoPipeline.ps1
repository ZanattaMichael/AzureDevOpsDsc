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
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoPipeline] Creating pipeline '$PipelineName'."

    $project    = Resolve-AzDoProject -ProjectName $ProjectName

    if (-not $project)
    {
        Write-Error "[New-AzDoPipeline] Project '$ProjectName' not found."
        return
    }

    $repository = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories'
    if (-not $repository)
    {
        # Repository may have been created after the cache was built at init — fall back to a live lookup.
        Write-Verbose "[New-AzDoPipeline] Repository '$RepositoryName' not in cache — falling back to live API lookup."
        $allRepos   = List-DevOpsGitRepository -OrganizationName (Get-AzDoOrganizationName) -ProjectName $ProjectName
        $repository = $allRepos | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
    }

    $params = @{
        ApiUri         = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName    = $ProjectName
        PipelineName   = $PipelineName
        FolderPath     = $FolderPath
        YamlFilePath   = $YamlPath
        RepositoryId   = if ($repository) { $repository.id } else { $null }
        RepositoryName = $RepositoryName
        DefaultBranch  = 'refs/heads/{0}' -f $DefaultBranch
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
    Write-Verbose "[New-AzDoPipeline] Pipeline '$PipelineName' created."
}
