<#
.SYNOPSIS
Updates a rule on an Azure DevOps work item type.

.DESCRIPTION
Replaces the rule's conditions, actions and disabled flag. The API takes the complete rule, so the
configuration's conditions and actions are the whole set - anything omitted from them is removed.

Where the configuration does not state conditions or actions at all, the live values are sent back
unchanged, so toggling IsDisabled does not wipe a rule's logic.

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
Set-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Severity required' -IsDisabled $true
#>
Function Set-AzDoProcessRule
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

    Write-Verbose "[Set-AzDoProcessRule] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $ruleId           = $LookupResult.ruleId
    $live             = $LookupResult.liveCache

    if ([String]::IsNullOrWhiteSpace($ruleId))
    {
        Write-Error "[Set-AzDoProcessRule] Rule '$RuleName' was not found on work item type '$WorkItemTypeName'."
        return
    }

    # Fall back to the live rule for anything the configuration does not state, so that changing
    # one part of a rule does not blank the rest.
    $effectiveConditions = if ($PSBoundParameters.ContainsKey('Conditions') -and $null -ne $Conditions) { @($Conditions) } else { @($live.conditions) }
    $effectiveActions    = if ($PSBoundParameters.ContainsKey('Actions') -and $null -ne $Actions)       { @($Actions) }    else { @($live.actions) }
    $effectiveDisabled   = if ($PSBoundParameters.ContainsKey('IsDisabled'))                             { [bool]$IsDisabled } else { [bool]$live.isDisabled }

    # The live values come back as objects; the API function takes hashtables.
    $conditionTables = @($effectiveConditions | ForEach-Object {
        if ($_ -is [System.Collections.IDictionary]) { $_ }
        else {
            $table = @{}
            foreach ($property in $_.PSObject.Properties) { $table[$property.Name] = $property.Value }
            $table
        }
    })

    $actionTables = @($effectiveActions | ForEach-Object {
        if ($_ -is [System.Collections.IDictionary]) { $_ }
        else {
            $table = @{}
            foreach ($property in $_.PSObject.Properties) { $table[$property.Name] = $property.Value }
            $table
        }
    })

    Write-Verbose "[Set-AzDoProcessRule] Updating rule '$RuleName' on work item type '$WorkItemTypeName'."

    return (Update-DevOpsProcessRule -Organization $OrganizationName -ProcessId $processId `
        -WorkItemTypeRefName $refName -RuleId $ruleId -RuleName $RuleName `
        -Conditions $conditionTables -Actions $actionTables -IsDisabled $effectiveDisabled)
}
