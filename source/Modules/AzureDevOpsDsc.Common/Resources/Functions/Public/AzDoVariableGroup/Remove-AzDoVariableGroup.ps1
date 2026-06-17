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

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if (-not $project)
    {
        Write-Error "[Remove-AzDoVariableGroup] Project '$ProjectName' not found; cannot resolve project id."
        return
    }

    $vg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Type 'LiveVariableGroups'
    if (-not $vg)
    {
        # Variable group may have been created after the cache was built at init — fall back to a live lookup.
        $allVGs = List-DevOpsVariableGroups -ApiUri ('https://dev.azure.com/{0}' -f (Get-AzDoOrganizationName)) -ProjectName $ProjectName
        $vg     = $allVGs | Where-Object { $_.name -eq $VariableGroupName } | Select-Object -First 1
    }

    if (-not $vg)
    {
        # Already absent — nothing to remove (desired state achieved).
        Write-Verbose "[Remove-AzDoVariableGroup] Variable group '$VariableGroupName' not found; already absent."
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
