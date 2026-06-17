Function Get-AzDoPipeline
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoPipeline] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $PipelineName
    $pipeline = Get-CacheItem -Key $cacheKey -Type 'LivePipelines'

    if (-not $pipeline)
    {
        Write-Verbose "[Get-AzDoPipeline] Pipeline '$PipelineName' not in cache — falling back to live API lookup."
        $OrgName     = Get-AzDoOrganizationName
        $allPipelines = List-DevOpsPipelines -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $pipeline    = $allPipelines | Where-Object { $_.name -eq $PipelineName } | Select-Object -First 1
        if ($pipeline) { Add-CacheItem -Key $cacheKey -Value $pipeline -Type 'LivePipelines' }
    }

    if ($pipeline)
    {
        Write-Verbose "[Get-AzDoPipeline] Pipeline '$PipelineName' found."
        $result.liveCache = $pipeline
        $result.status    = [DSCGetSummaryState]::Unchanged
    }
    else
    {
        Write-Verbose "[Get-AzDoPipeline] Pipeline '$PipelineName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
    }

    return $result
}
