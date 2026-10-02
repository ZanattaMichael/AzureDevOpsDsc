<#
.SYNOPSIS
Creates a rule on a work item type of an inherited process.

.DESCRIPTION
Creates a conditional rule. Conditions and actions are passed through as the API expects them:

  Condition: @{ conditionType = 'when'; field = 'System.State'; value = 'Active' }
  Action:    @{ actionType = 'makeRequired'; targetField = 'Custom.Severity'; value = '' }

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER RuleName
The name of the rule.

.PARAMETER Conditions
The conditions under which the rule applies.

.PARAMETER Actions
The actions the rule performs.

.PARAMETER IsDisabled
Whether the rule is disabled.

.EXAMPLE
New-DevOpsProcessRule -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -RuleName 'Severity required when active' -Conditions $c -Actions $a
#>
Function New-DevOpsProcessRule
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

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/rules?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    $body = @{
        name       = $RuleName
        conditions = @($Conditions)
        actions    = @($Actions)
        isDisabled = $IsDisabled
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 8))
    }
    catch
    {
        Write-Error "[New-DevOpsProcessRule] Failed to create rule '$RuleName' on '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
