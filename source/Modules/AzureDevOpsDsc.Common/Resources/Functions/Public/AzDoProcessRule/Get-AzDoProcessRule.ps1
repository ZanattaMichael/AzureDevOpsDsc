<#
.SYNOPSIS
Retrieves the current state of a rule on an Azure DevOps work item type.

.DESCRIPTION
Finds the rule by name and compares its conditions, actions and disabled flag against the desired
state.

Conditions and actions are normalized before comparison: a configuration supplies hashtables and
the API returns objects, and the API also fills in keys the configuration omitted. Comparing them
raw would report drift on every Test(). See ConvertTo-NormalizedRuleClause.

Both are compared as ordered sequences, since order is significant within a rule.

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
Get-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Severity required'
#>
Function Get-AzDoProcessRule
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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

    Write-Verbose "[Get-AzDoProcessRule] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $result = @{
        Ensure            = [Ensure]::Absent
        ProcessName       = $ProcessName
        WorkItemTypeName  = $WorkItemTypeName
        RuleName          = $RuleName
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $resolved = Resolve-AzDoProcessWorkItemType -Organization $OrganizationName -ProcessName $ProcessName -WorkItemTypeName $WorkItemTypeName

    if (-not $resolved.IsCustomizable -or $null -eq $resolved.WorkItemType)
    {
        Write-Error "[Get-AzDoProcessRule] Cannot read rules for '$WorkItemTypeName' on process '$ProcessName' ($($resolved.Reason))."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = $resolved.Reason
        return $result
    }

    $processId = $resolved.Process.id
    $refName   = $resolved.WorkItemType.referenceName

    $result.processId           = $processId
    $result.workItemTypeRefName = $refName

    $rules = List-DevOpsProcessRules -Organization $OrganizationName -ProcessId $processId -WorkItemTypeRefName $refName

    # Rule ids are assigned by Azure DevOps, so the name is the only stable handle a configuration
    # has on a rule.
    $rule = $rules | Where-Object { $_.name -eq $RuleName } | Select-Object -First 1

    if ($null -eq $rule)
    {
        Write-Verbose "[Get-AzDoProcessRule] Rule '$RuleName' does not exist on work item type '$WorkItemTypeName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.ruleId        = $rule.id
    $result.customization = $rule.customizationType
    $result.liveCache     = $rule
    $result.Ensure        = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('Conditions') -and $null -ne $Conditions)
    {
        $desired = @($Conditions | ForEach-Object { ConvertTo-NormalizedRuleClause -Clause $_ })
        $current = @($rule.conditions | ForEach-Object { ConvertTo-NormalizedRuleClause -Clause $_ })

        if (($desired -join '|') -ne ($current -join '|'))
        {
            Write-Verbose "[Get-AzDoProcessRule] Conditions differ for rule '$RuleName'."
            $propertiesChanged += 'Conditions'
        }
    }

    if ($PSBoundParameters.ContainsKey('Actions') -and $null -ne $Actions)
    {
        $desired = @($Actions | ForEach-Object { ConvertTo-NormalizedRuleClause -Clause $_ })
        $current = @($rule.actions | ForEach-Object { ConvertTo-NormalizedRuleClause -Clause $_ })

        if (($desired -join '|') -ne ($current -join '|'))
        {
            Write-Verbose "[Get-AzDoProcessRule] Actions differ for rule '$RuleName'."
            $propertiesChanged += 'Actions'
        }
    }

    if ($PSBoundParameters.ContainsKey('IsDisabled'))
    {
        if ([bool]$rule.isDisabled -ne $IsDisabled)
        {
            Write-Verbose "[Get-AzDoProcessRule] IsDisabled differs for rule '$RuleName'."
            $propertiesChanged += 'IsDisabled'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoProcessRule] Rule '$RuleName' status: $($result.status)."

    return $result
}
