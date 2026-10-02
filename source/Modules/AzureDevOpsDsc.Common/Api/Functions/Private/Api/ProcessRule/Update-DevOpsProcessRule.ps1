<#
.SYNOPSIS
Updates a rule on a work item type.

.DESCRIPTION
Replaces a rule's conditions, actions and disabled flag. The API takes the complete rule, so the
conditions and actions supplied are the whole set - anything omitted is removed.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER RuleId
The id of the rule to update.

.PARAMETER RuleName
The name the rule should have.

.PARAMETER Conditions
The complete set of conditions.

.PARAMETER Actions
The complete set of actions.

.PARAMETER IsDisabled
Whether the rule is disabled.

.EXAMPLE
Update-DevOpsProcessRule -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -RuleId $ruleId -RuleName 'Severity required' -Conditions $c -Actions $a
#>
Function Update-DevOpsProcessRule
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

        [Parameter(Mandatory = $true)]
        [String]$RuleName,

        [Parameter(Mandatory = $true)]
        [HashTable[]]$Conditions,

        [Parameter(Mandatory = $true)]
        [HashTable[]]$Actions,

        [Parameter()]
        [Boolean]$IsDisabled = $false,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/rules/{3}?api-version={4}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $RuleId, $ApiVersion

    $body = @{
        id         = $RuleId
        name       = $RuleName
        conditions = @($Conditions)
        actions    = @($Actions)
        isDisabled = $IsDisabled
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PUT' -Body ($body | ConvertTo-Json -Depth 8))
    }
    catch
    {
        Write-Error "[Update-DevOpsProcessRule] Failed to update rule '$RuleName' on '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
