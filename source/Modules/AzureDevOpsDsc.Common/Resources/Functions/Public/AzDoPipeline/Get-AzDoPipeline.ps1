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

    $pipeline = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $PipelineName) -Type 'LivePipelines'

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
