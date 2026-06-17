Function Remove-AzDoTaskGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TaskGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$Category = 'Deploy',
        [Parameter()][HashTable[]]$Tasks,
        [Parameter()][HashTable[]]$Inputs,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoTaskGroup] Removing task group '$TaskGroupName'."
    $tg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TaskGroupName) -Type 'LiveTaskGroups'
    if (-not $tg) { Write-Error "[Remove-AzDoTaskGroup] Task group not found."; return }
    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName = $ProjectName
        TaskGroupId = $tg.id
    }
    Remove-DevOpsTaskGroup @params
    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TaskGroupName) -Type 'LiveTaskGroups'
    Export-CacheObject -CacheType 'LiveTaskGroups' -Content $AzDoLiveTaskGroups
}
