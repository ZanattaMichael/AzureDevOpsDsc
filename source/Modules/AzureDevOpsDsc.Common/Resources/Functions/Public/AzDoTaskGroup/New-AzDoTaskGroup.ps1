Function New-AzDoTaskGroup
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
    Write-Verbose "[New-AzDoTaskGroup] Creating task group '$TaskGroupName'."
    $params = @{
        ApiUri        = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName   = $ProjectName
        TaskGroupName = $TaskGroupName
        Description   = $Description
        Category      = $Category
        Tasks         = if ($Tasks)  { $Tasks }  else { @() }
        Inputs        = if ($Inputs) { $Inputs } else { @() }
    }
    $value = New-DevOpsTaskGroup @params
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TaskGroupName) -Value $value -Type 'LiveTaskGroups'
    Export-CacheObject -CacheType 'LiveTaskGroups' -Content $AzDoLiveTaskGroups
    Refresh-CacheObject -CacheType 'LiveTaskGroups'
}
