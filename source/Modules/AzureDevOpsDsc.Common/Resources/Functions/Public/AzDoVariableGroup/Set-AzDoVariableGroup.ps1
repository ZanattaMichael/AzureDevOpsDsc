Function Set-AzDoVariableGroup
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

    Write-Verbose "[Set-AzDoVariableGroup] Updating variable group '$VariableGroupName'."

    $vg = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Type 'LiveVariableGroups'

    if (-not $vg)
    {
        Write-Error "[Set-AzDoVariableGroup] Variable group '$VariableGroupName' not found in cache."
        return
    }

    $params = @{
        ApiUri            = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName       = $ProjectName
        VariableGroupId   = $vg.id
        VariableGroupName = $VariableGroupName
        Description       = $Description
        Type              = $VariableGroupType
        Variables         = if ($Variables) { $Variables } else { @{} }
    }

    $value = Set-DevOpsVariableGroup @params

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Value $value -Type 'LiveVariableGroups'
    Export-CacheObject -CacheType 'LiveVariableGroups' -Content $AzDoLiveVariableGroups
    Refresh-CacheObject -CacheType 'LiveVariableGroups'
    Write-Verbose "[Set-AzDoVariableGroup] Variable group '$VariableGroupName' updated."
}
