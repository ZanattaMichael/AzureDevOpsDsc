Function Set-AzDoPipeline
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

    Write-Verbose "[Set-AzDoPipeline] Updating pipeline '$PipelineName'."

    $pipeline   = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Type 'LivePipelines'
    $repository = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories'

    if (-not $pipeline)
    {
        Write-Error "[Set-AzDoPipeline] Pipeline '$PipelineName' not found in cache."
        return
    }

    $params = @{
        ApiUri         = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName    = $ProjectName
        PipelineId     = $pipeline.id
        PipelineName   = $PipelineName
        FolderPath     = $FolderPath
        YamlFilePath   = $YamlPath
        RepositoryId   = if ($repository) { $repository.id } else { $null }
        RepositoryName = $RepositoryName
        DefaultBranch  = 'refs/heads/{0}' -f $DefaultBranch
    }

    $value = Set-DevOpsPipeline @params

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Value $value -Type 'LivePipelines'
    Export-CacheObject -CacheType 'LivePipelines' -Content $AzDoLivePipelines
    Refresh-CacheObject -CacheType 'LivePipelines'
    Write-Verbose "[Set-AzDoPipeline] Pipeline '$PipelineName' updated."
}
