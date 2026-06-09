Function Remove-AzDoPipeline
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

    Write-Verbose "[Remove-AzDoPipeline] Removing pipeline '$PipelineName'."

    $pipeline = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Type 'LivePipelines'

    if (-not $pipeline)
    {
        Write-Error "[Remove-AzDoPipeline] Pipeline '$PipelineName' not found in cache."
        return
    }

    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName = $ProjectName
        PipelineId  = $pipeline.id
    }

    Remove-DevOpsPipeline @params

    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Type 'LivePipelines'
    Export-CacheObject -CacheType 'LivePipelines' -Content $AzDoLivePipelines
    Write-Verbose "[Remove-AzDoPipeline] Pipeline '$PipelineName' removed."
}
