Function Get-AzDoVariableGroup
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoVariableGroup] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    $cacheKey = '{0}\{1}' -f $ProjectName, $VariableGroupName
    $vg = Get-CacheItem -Key $cacheKey -Type 'LiveVariableGroups'

    if (-not $vg)
    {
        Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' not in cache — falling back to live API lookup."
        $OrgName = Get-AzDoOrganizationName
        $allVGs  = List-DevOpsVariableGroups -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $vg      = $allVGs | Where-Object { $_.name -eq $VariableGroupName } | Select-Object -First 1
        if ($vg) { Add-CacheItem -Key $cacheKey -Value $vg -Type 'LiveVariableGroups' }
    }

    if ($vg)
    {
        Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' found."
        $result.liveCache = $vg
        $result.status    = [DSCGetSummaryState]::Unchanged
    }
    else
    {
        Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
    }

    return $result
}
