<#
.SYNOPSIS
Updates an Azure DevOps variable group to the configured state.

.DESCRIPTION
Sends the group back to the API with the configured description and variables. A setting the
configuration does not state is re-sent as it is live, so a Set that corrects the description
does not wipe the variables (or the other way round).

Variables are normalized with ConvertTo-AzDoVariableGroupVariables, so a configured secret is
written with isSecret = $true. A secret's value is sent only when the configuration supplies
one; '@{ isSecret = $true }' with no value - and every live secret re-sent because Variables is
not configured - carries a null value, which Azure DevOps treats as "keep the stored secret".

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER VariableGroupName
The name of the variable group.

.PARAMETER Description
The desired description. Left as it is live when empty.

.PARAMETER VariableGroupType
The variable group type.

.PARAMETER Variables
The desired variables, as @{ NAME = 'value' } or @{ NAME = @{ value = 'v'; isSecret = $true } }.
Left as they are live when not supplied.

.PARAMETER AllowAccess
Accepted for parity with the resource; not written here (pipeline access is the
pipelinePermissions API).

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.
#>
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

    # Only what the configuration states is changed; the rest is re-sent as it is live. The API
    # replaces the whole variable set on PUT, so sending @{} here would delete every variable.
    $desiredDescription = if (-not [String]::IsNullOrEmpty($Description)) { $Description } else { [String]$vg.description }

    $desiredVariables = if ($PSBoundParameters.ContainsKey('Variables') -and ($null -ne $Variables))
    {
        ConvertTo-AzDoVariableGroupVariables -Variables $Variables
    }
    else
    {
        # Live secrets come back with a null value; re-sending them that way keeps the stored
        # secret. Their values are never read or logged.
        ConvertTo-AzDoVariableGroupVariables -Variables $vg.variables
    }

    Write-Verbose "[Set-AzDoVariableGroup] Sending variables: $(@($desiredVariables.Keys | Sort-Object) -join ', ')."

    $params = @{
        ApiUri            = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName       = $ProjectName
        VariableGroupId   = $vg.id
        VariableGroupName = $VariableGroupName
        Description       = $desiredDescription
        Type              = $VariableGroupType
        Variables         = $desiredVariables
    }

    $value = Set-DevOpsVariableGroup @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoVariableGroup] Set-DevOpsVariableGroup returned null. Check authentication token and organization settings."
        return
    }

    # The write response echoes the request rather than the stored group - its top-level
    # description is not what a project-scoped read returns - and a later Get compares the
    # configuration against the cache, so cache what the API now reads back for the project.
    $live = List-DevOpsVariableGroups -ApiUri ('https://dev.azure.com/{0}' -f (Get-AzDoOrganizationName)) -ProjectName $ProjectName |
        Where-Object { $_.id -eq $value.id } | Select-Object -First 1
    if ($live)
    {
        $value = $live
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $VariableGroupName) -Value $value -Type 'LiveVariableGroups'
    Export-CacheObject -CacheType 'LiveVariableGroups' -Content $AzDoLiveVariableGroups
    Refresh-CacheObject -CacheType 'LiveVariableGroups'
    Write-Verbose "[Set-AzDoVariableGroup] Variable group '$VariableGroupName' updated."
}
