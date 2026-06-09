Function New-AzDoPipelineEnvironment
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
    Write-Verbose "[New-AzDoPipelineEnvironment] Creating environment '$EnvironmentName'."
    $params = @{
        ApiUri          = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName     = $ProjectName
        EnvironmentName = $EnvironmentName
        Description     = $Description
    }
    $value = New-DevOpsPipelineEnvironment @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoPipelineEnvironment] New-DevOpsPipelineEnvironment returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $EnvironmentName) -Value $value -Type 'LivePipelineEnvironments'
    Export-CacheObject -CacheType 'LivePipelineEnvironments' -Content $AzDoLivePipelineEnvironments
    Refresh-CacheObject -CacheType 'LivePipelineEnvironments'
}
