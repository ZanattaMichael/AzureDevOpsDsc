Function Get-AzDoPipelineEnvironment
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$EnvironmentName,
        [Parameter()][string]$Description,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoPipelineEnvironment] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $cacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    $env = Get-CacheItem -Key $cacheKey -Type 'LivePipelineEnvironments'
    if (-not $env)
    {
        Write-Verbose "[Get-AzDoPipelineEnvironment] Environment '$cacheKey' not in cache — falling back to live API lookup."
        $OrgName = Get-AzDoOrganizationName
        $allEnvs = List-DevOpsPipelineEnvironments -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $env     = $allEnvs | Where-Object { $_.name -eq $EnvironmentName } | Select-Object -First 1
        if ($env) { Add-CacheItem -Key $cacheKey -Value $env -Type 'LivePipelineEnvironments' }
    }
    if ($env) { $result.liveCache = $env; $result.status = [DSCGetSummaryState]::Unchanged }
    else       { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
