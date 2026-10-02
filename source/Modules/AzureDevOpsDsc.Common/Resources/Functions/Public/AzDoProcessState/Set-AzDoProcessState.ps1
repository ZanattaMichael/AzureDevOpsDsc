<#
.SYNOPSIS
Updates a custom workflow state on an Azure DevOps work item type.

.DESCRIPTION
Applies the configured colour and order.

The category is not updated: it is fixed at creation, and Get reports a mismatch as an error rather
than passing it here.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER WorkItemTypeName
The display name of the work item type.

.PARAMETER StateName
The name of the state.

.PARAMETER StateCategory
'Proposed', 'InProgress', 'Resolved', 'Completed' or 'Removed'.

.PARAMETER Color
The hex colour without a leading '#'.

.PARAMETER Order
The position of the state within its category.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Triaged' -Color '00FF00'
#>
Function Set-AzDoProcessState
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Process')]
        [System.String]$ProcessName,

        [Parameter(Mandatory = $true)]
        [Alias('WorkItemType')]
        [System.String]$WorkItemTypeName,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$StateName,

        [Parameter()]
        [System.String]$StateCategory,

        [Parameter()]
        [System.String]$Color,

        [Parameter()]
        [System.Int32]$Order,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoProcessState] Started."

    if ($LookupResult.reason -eq 'StateCategoryImmutable')
    {
        Write-Error "[Set-AzDoProcessState] Cannot change the category of state '$StateName' after creation. No change was made."
        return
    }

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $stateId          = $LookupResult.stateId

    if ([String]::IsNullOrWhiteSpace($stateId))
    {
        Write-Error "[Set-AzDoProcessState] State '$StateName' was not found on work item type '$WorkItemTypeName'."
        return
    }

    $params = @{
        Organization        = $OrganizationName
        ProcessId           = $processId
        WorkItemTypeRefName = $refName
        StateId             = $stateId
    }

    if (-not [String]::IsNullOrWhiteSpace($Color)) { $params.Color = $Color.TrimStart('#') }
    if ($PSBoundParameters.ContainsKey('Order'))   { $params.Order = $Order }

    Write-Verbose "[Set-AzDoProcessState] Updating state '$StateName'."

    return (Update-DevOpsProcessState @params)
}
