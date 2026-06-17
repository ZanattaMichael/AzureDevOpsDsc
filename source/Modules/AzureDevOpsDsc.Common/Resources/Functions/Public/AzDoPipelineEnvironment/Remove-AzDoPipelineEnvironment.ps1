Function Remove-AzDoPipelineEnvironment
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$EnvironmentName,
        [Parameter()][string]$Description,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoPipelineEnvironment] Removing environment '$EnvironmentName'."
    $env = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'
    if (-not $env) { Write-Error "[Remove-AzDoPipelineEnvironment] Environment not found."; return }
    $params = @{
        ApiUri        = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName   = $ProjectName
        EnvironmentId = $env.id
    }
    Remove-DevOpsPipelineEnvironment @params
    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'
    Export-CacheObject -CacheType 'LivePipelineEnvironments' -Content $AzDoLivePipelineEnvironments
}
