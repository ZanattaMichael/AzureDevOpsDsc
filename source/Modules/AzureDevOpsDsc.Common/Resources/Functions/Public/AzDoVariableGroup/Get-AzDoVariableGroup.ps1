<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps variable group.

.DESCRIPTION
Looks the variable group up in the LiveVariableGroups cache, falling back to a live list of the
project's variable groups. Description and Variables are compared only when the configuration
states them, so a configuration that only declares the group does not report drift against
settings changed in the UI.

Variables are compared as a complete set: a variable that is live but not configured, or
configured but not live, is drift. A non-secret variable is compared by value. A secret
variable's value can never be read back from Azure DevOps, so it is compared only on existence
and on being secret; its value is never logged and never compared.

AllowAccess is not compared: the variable group object does not carry it (pipeline access is the
pipelinePermissions API, which AzDoPipelineAuthorization manages).

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER VariableGroupName
The name of the variable group.

.PARAMETER Description
The desired description. Left unmanaged when empty.

.PARAMETER VariableGroupType
The variable group type. Not compared; the type of an existing group cannot be changed.

.PARAMETER Variables
The desired variables, as @{ NAME = 'value' } or @{ NAME = @{ value = 'v'; isSecret = $true } }.
Left unmanaged when not supplied.

.PARAMETER AllowAccess
Not compared; see DESCRIPTION.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoVariableGroup -ProjectName 'Contoso' -VariableGroupName 'Shared' -Variables @{ APP_ENV = 'prod' }
#>
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

    if (-not $vg)
    {
        Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' found."
    $result.liveCache = $vg
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    # The DSC base class passes every property, so an unset Description arrives as an empty
    # string; only a stated description is compared.
    if (-not [String]::IsNullOrEmpty($Description) -and ($Description -ne [String]$vg.description))
    {
        Write-Verbose "[Get-AzDoVariableGroup] Description differs for '$VariableGroupName'."
        $propertiesChanged += 'Description'
    }

    if ($PSBoundParameters.ContainsKey('Variables') -and ($null -ne $Variables))
    {
        $desired = ConvertTo-AzDoVariableGroupVariables -Variables $Variables
        $live    = ConvertTo-AzDoVariableGroupVariables -Variables $vg.variables

        if (Test-AzDoVariableGroupVariableDrift -DesiredVariables $desired -LiveVariables $live -VariableGroupName $VariableGroupName)
        {
            $propertiesChanged += 'Variables'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoVariableGroup] Variable group '$VariableGroupName' status: $($result.status)."

    return $result
}
