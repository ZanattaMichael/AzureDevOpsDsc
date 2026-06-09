Function Remove-AzDoCheckConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ResourceName,
        [Parameter(Mandatory = $true)][string]$ResourceType,
        [Parameter(Mandatory = $true)][string]$CheckType,
        [Parameter()][HashTable]$Settings,
        [Parameter()][uint32]$TimeoutInMinutes = 43200,
        [Parameter()][bool]$Enabled = $true,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoCheckConfiguration] Removing check '$CheckType' on $ResourceType '$ResourceName'."
    $cacheKey = '{0}\{1}\{2}\{3}' -f $ProjectName, $ResourceType, $ResourceName, $CheckType
    $check = Get-CacheItem -Key $cacheKey -Type 'LiveCheckConfigurations'
    if (-not $check) { Write-Error "[Remove-AzDoCheckConfiguration] Check configuration not found."; return }
    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName = $ProjectName
        CheckId     = $check.id
    }
    Remove-DevOpsCheckConfiguration @params
    Remove-CacheItem -Key $cacheKey -Type 'LiveCheckConfigurations'
    Export-CacheObject -CacheType 'LiveCheckConfigurations' -Content $AzDoLiveCheckConfigurations
}
