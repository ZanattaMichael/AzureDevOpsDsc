<#
.SYNOPSIS
Removes a rule from a work item type.

.DESCRIPTION
Deletes a custom rule. Rules inherited from the parent process cannot be deleted - they can only
be disabled.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER RuleId
The id of the rule to delete.

.EXAMPLE
Remove-DevOpsProcessRule -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -RuleId $ruleId
#>
Function Remove-DevOpsProcessRule
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
        [String]$RuleId,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/rules/{3}?api-version={4}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $RuleId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsProcessRule] Failed to remove rule '$RuleId' from '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
