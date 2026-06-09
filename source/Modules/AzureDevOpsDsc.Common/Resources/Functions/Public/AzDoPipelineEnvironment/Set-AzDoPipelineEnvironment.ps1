Function Set-AzDoPipelineEnvironment
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
    Write-Verbose "[Set-AzDoPipelineEnvironment] Updating environment '$EnvironmentName'."
    $env = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Type 'LivePipelineEnvironments'
    if (-not $env) { Write-Error "[Set-AzDoPipelineEnvironment] Environment not found."; return }
    $params = @{
        ApiUri          = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName     = $ProjectName
        EnvironmentId   = $env.id
        EnvironmentName = $EnvironmentName
        Description     = $Description
    }
    $value = Set-DevOpsPipelineEnvironment @params
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Value $value -Type 'LivePipelineEnvironments'
    Export-CacheObject -CacheType 'LivePipelineEnvironments' -Content $AzDoLivePipelineEnvironments
    Refresh-CacheObject -CacheType 'LivePipelineEnvironments'
}
