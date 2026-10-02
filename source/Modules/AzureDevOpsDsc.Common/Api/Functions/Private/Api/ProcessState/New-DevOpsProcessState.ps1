<#
.SYNOPSIS
Creates a custom workflow state on a work item type.

.DESCRIPTION
Adds a state to the work item type's workflow. A state belongs to a category, which is what the
boards and the Analytics service use to decide whether an item counts as not started, in progress
or done - the category matters more than the name.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER StateName
The name of the state.

.PARAMETER StateCategory
'Proposed', 'InProgress', 'Resolved', 'Completed' or 'Removed'.

.PARAMETER Color
The hex colour without a leading '#'.

.PARAMETER Order
The position of the state within its category.

.EXAMPLE
New-DevOpsProcessState -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -StateName 'Triaged' -StateCategory 'InProgress'
#>
Function New-DevOpsProcessState
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProcessId,

        [Parameter(Mandatory = $true)]
        [String]$WorkItemTypeRefName,

        [Parameter(Mandatory = $true)]
        [String]$StateName,

        [Parameter(Mandatory = $true)]
        [String]$StateCategory,

        [Parameter()]
        [String]$Color = 'b2b2b2',

        [Parameter()]
        [Object]$Order,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/states?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    $body = @{
        name         = $StateName
        stateCategory = $StateCategory
        color        = $Color
    }

    if ($null -ne $Order) { $body.order = [int]$Order }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[New-DevOpsProcessState] Failed to create state '$StateName' on '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
