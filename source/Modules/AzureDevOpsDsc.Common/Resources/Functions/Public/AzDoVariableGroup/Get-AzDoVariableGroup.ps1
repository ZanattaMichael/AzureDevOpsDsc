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

    $vg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Type 'LiveVariableGroups'

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
