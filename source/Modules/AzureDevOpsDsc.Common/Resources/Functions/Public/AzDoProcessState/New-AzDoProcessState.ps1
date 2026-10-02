<#
.SYNOPSIS
Creates a custom workflow state on an Azure DevOps work item type.

.DESCRIPTION
Adds a state to the work item type's workflow, in the configured category.

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
New-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Triaged' -StateCategory 'InProgress'
#>
Function New-AzDoProcessState
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

    Write-Verbose "[New-AzDoProcessState] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName

    if ([String]::IsNullOrWhiteSpace($processId) -or [String]::IsNullOrWhiteSpace($refName))
    {
        $resolved  = Resolve-AzDoProcessWorkItemType -Organization $OrganizationName -ProcessName $ProcessName -WorkItemTypeName $WorkItemTypeName
        $processId = $resolved.Process.id
        $refName   = $resolved.WorkItemType.referenceName
    }

    if ([String]::IsNullOrWhiteSpace($refName))
    {
        Write-Error "[New-AzDoProcessState] Work item type '$WorkItemTypeName' was not found on process '$ProcessName'."
        return
    }

    if ([String]::IsNullOrWhiteSpace($StateCategory))
    {
        Write-Error "[New-AzDoProcessState] StateCategory is required to create state '$StateName'. Boards and Analytics reason about categories, not state names."
        return
    }

    $params = @{
        Organization        = $OrganizationName
        ProcessId           = $processId
        WorkItemTypeRefName = $refName
        StateName           = $StateName
        StateCategory       = $StateCategory
    }

    if (-not [String]::IsNullOrWhiteSpace($Color))  { $params.Color = $Color.TrimStart('#') }
    if ($PSBoundParameters.ContainsKey('Order'))    { $params.Order = $Order }

    Write-Verbose "[New-AzDoProcessState] Creating state '$StateName' on work item type '$WorkItemTypeName'."

    $created = New-DevOpsProcessState @params

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoProcessState] Failed to create state '$StateName' on work item type '$WorkItemTypeName'."
        return
    }

    return $created
}
