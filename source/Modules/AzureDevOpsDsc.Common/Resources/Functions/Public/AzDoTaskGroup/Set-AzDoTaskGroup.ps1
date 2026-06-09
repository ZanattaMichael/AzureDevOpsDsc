Function Set-AzDoTaskGroup
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
    Write-Verbose "[Set-AzDoTaskGroup] Updating task group '$TaskGroupName'."
    $tg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TaskGroupName) -Type 'LiveTaskGroups'
    if (-not $tg) { Write-Error "[Set-AzDoTaskGroup] Task group not found."; return }
    $params = @{
        ApiUri        = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName   = $ProjectName
        TaskGroupId   = $tg.id
        TaskGroupName = $TaskGroupName
        Description   = $Description
        Category      = $Category
        Tasks         = if ($Tasks)  { $Tasks }  else { @() }
        Inputs        = if ($Inputs) { $Inputs } else { @() }
    }
    $value = Set-DevOpsTaskGroup @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoTaskGroup] Set-DevOpsTaskGroup returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TaskGroupName) -Value $value -Type 'LiveTaskGroups'
    Export-CacheObject -CacheType 'LiveTaskGroups' -Content $AzDoLiveTaskGroups
    Refresh-CacheObject -CacheType 'LiveTaskGroups'
}
