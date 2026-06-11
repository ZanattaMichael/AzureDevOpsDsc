Function Remove-AzDoVariableGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$VariableGroupName,
        [Parameter()][string]$Description,
        [Parameter()][string]$VariableGroupType = 'Vsts',
        [Parameter()][HashTable]$Variables,
        [Parameter()][bool]$AllowAccess = $false,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoVariableGroup] Removing variable group '$VariableGroupName'."

    $vg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Type 'LiveVariableGroups'

    if (-not $vg)
    {
        Write-Error "[Remove-AzDoVariableGroup] Variable group '$VariableGroupName' not found in cache."
        return
    }

    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $project)
    {
        Write-Error "[Remove-AzDoVariableGroup] Project '$ProjectName' not found in cache; cannot resolve project id."
        return
    }

    $params = @{
        ApiUri          = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId       = $project.id
        VariableGroupId = $vg.id
    }

    Remove-DevOpsVariableGroup @params

    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Type 'LiveVariableGroups'
    Export-CacheObject -CacheType 'LiveVariableGroups' -Content $AzDoLiveVariableGroups
    Write-Verbose "[Remove-AzDoVariableGroup] Variable group '$VariableGroupName' removed."
}
