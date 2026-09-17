<#
.SYNOPSIS
Updates a custom workflow state on a work item type.

.DESCRIPTION
PATCHes a state's colour and order.

A state's category cannot be changed after creation - moving a state between categories would
reclassify every work item currently in it, so the API does not allow it and the resource reports
the mismatch rather than recreating the state.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER StateId
The id of the state.

.PARAMETER Color
The hex colour without a leading '#'.

.PARAMETER Order
The position of the state within its category.

.EXAMPLE
Update-DevOpsProcessState -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -StateId $stateId -Color '00FF00'
#>
Function Update-DevOpsProcessState
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
        [String]$StateId,

        [Parameter()]
        [String]$Color,

        [Parameter()]
        [Object]$Order,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/states/{3}?api-version={4}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $StateId, $ApiVersion

    $body = @{}
    if (-not [String]::IsNullOrWhiteSpace($Color)) { $body.color = $Color }
    if ($null -ne $Order)                          { $body.order = [int]$Order }

    if ($body.Keys.Count -eq 0)
    {
        Write-Verbose "[Update-DevOpsProcessState] No updatable values supplied for state '$StateId'. No action taken."
        return $null
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[Update-DevOpsProcessState] Failed to update state '$StateId' on '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
