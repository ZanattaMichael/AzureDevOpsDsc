<#
.SYNOPSIS
Creates a rule on an Azure DevOps work item type.

.DESCRIPTION
Creates a conditional rule from the configured conditions and actions.

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
New-AzDoProcessRule -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -RuleName 'Severity required' -Conditions $c -Actions $a
#>
Function New-AzDoProcessRule
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

    Write-Verbose "[New-AzDoProcessRule] Started."

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
        Write-Error "[New-AzDoProcessRule] Work item type '$WorkItemTypeName' was not found on process '$ProcessName'."
        return
    }

    # A rule with no conditions or no actions is not a rule; the API's error for it is unhelpful.
    if ($null -eq $Conditions -or @($Conditions).Count -eq 0)
    {
        Write-Error "[New-AzDoProcessRule] Rule '$RuleName' needs at least one condition."
        return
    }

    if ($null -eq $Actions -or @($Actions).Count -eq 0)
    {
        Write-Error "[New-AzDoProcessRule] Rule '$RuleName' needs at least one action."
        return
    }

    Write-Verbose "[New-AzDoProcessRule] Creating rule '$RuleName' on work item type '$WorkItemTypeName'."

    $created = New-DevOpsProcessRule -Organization $OrganizationName -ProcessId $processId `
        -WorkItemTypeRefName $refName -RuleName $RuleName -Conditions @($Conditions) -Actions @($Actions) `
        -IsDisabled ([bool]$IsDisabled)

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoProcessRule] Failed to create rule '$RuleName' on work item type '$WorkItemTypeName'."
        return
    }

    return $created
}
