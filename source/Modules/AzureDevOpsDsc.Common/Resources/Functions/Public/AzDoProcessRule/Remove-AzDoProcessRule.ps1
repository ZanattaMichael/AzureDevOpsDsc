<#
.SYNOPSIS
Removes a rule from an Azure DevOps work item type.

.DESCRIPTION
Deletes a custom rule. Rules inherited from the parent process cannot be deleted - the resource
reports that and points at IsDisabled, which is the supported way to switch an inherited rule off.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER WorkItemTypeName
The display name of the work item type.

.PARAMETER RuleName
The name of the rule.

.PARAMETER Conditions
The conditions under which the rule applies.

.PARAMETER Actions
The actions the rule performs.

.PARAMETER IsDisabled
Whether the rule is disabled.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Severity required'
#>
Function Remove-AzDoProcessRule
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
        [System.String]$RuleName,

        [Parameter()]
        [AllowEmptyCollection()]
        [HashTable[]]$Conditions,

        [Parameter()]
        [AllowEmptyCollection()]
        [HashTable[]]$Actions,

        [Parameter()]
        [System.Boolean]$IsDisabled,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoProcessRule] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $ruleId           = $LookupResult.ruleId
    $customization    = $LookupResult.customization

    if ([String]::IsNullOrWhiteSpace($ruleId))
    {
        Write-Verbose "[Remove-AzDoProcessRule] Rule '$RuleName' does not exist on work item type '$WorkItemTypeName'. Nothing to remove."
        return
    }

    if ($customization -eq 'system' -or $customization -eq 'inherited')
    {
        Write-Error "[Remove-AzDoProcessRule] Rule '$RuleName' is inherited from the parent process and cannot be deleted. Set IsDisabled = \$true to switch it off instead."
        return
    }

    Write-Verbose "[Remove-AzDoProcessRule] Removing rule '$RuleName' from work item type '$WorkItemTypeName'."

    return (Remove-DevOpsProcessRule -Organization $OrganizationName -ProcessId $processId `
        -WorkItemTypeRefName $refName -RuleId $ruleId)
}
