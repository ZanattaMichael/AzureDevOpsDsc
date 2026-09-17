<#
.SYNOPSIS
    DSC resource for managing rules on a work item type of an Azure DevOps inherited process.

.DESCRIPTION
    Manages a conditional rule on a work item type - the "when this, then that" logic that makes a
    field required in a particular state, sets a default, or restricts a transition.

.NOTES
    Author: Michael Zanatta

    Conditions and actions are passed through as the API models them, rather than being wrapped in
    a friendlier abstraction, because the vocabulary is large and changes between API versions. A
    thin wrapper would have to be revised every time Azure DevOps adds an action type, and would
    silently not support the ones it did not know about.

        Conditions = @( @{ conditionType = 'when'; field = 'System.State'; value = 'Active' } )
        Actions    = @( @{ actionType = 'makeRequired'; targetField = 'Custom.Severity' } )

    Rules are matched by name, which is the only stable handle a configuration has - rule ids are
    assigned by Azure DevOps.

    Conditions and actions are replaced wholesale on update, because the API takes the complete
    rule. A configuration that states a rule states all of it.

    Inherited rules cannot be deleted, only disabled. The resource reports that rather than letting
    the API fail.

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
    Whether the rule is disabled. This is the only way to switch off an inherited rule.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoProcessRule SeverityRequired
    {
        ProcessName      = 'Contoso Agile'
        WorkItemTypeName = 'Incident'
        RuleName         = 'Severity required when active'
        Conditions       = @( @{ conditionType = 'when'; field = 'System.State'; value = 'Active' } )
        Actions          = @( @{ actionType = 'makeRequired'; targetField = 'Custom.Severity' } )
        Ensure           = 'Present'
    }
#>

[DscResource()]
class AzDoProcessRule : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Process')]
    [System.String]$ProcessName

    [DscProperty(Mandatory)]
    [Alias('WorkItemType')]
    [System.String]$WorkItemTypeName

    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$RuleName

    [DscProperty()]
    [HashTable[]]$Conditions

    [DscProperty()]
    [HashTable[]]$Actions

    [DscProperty()]
    [System.Boolean]$IsDisabled = $false

    AzDoProcessRule()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoProcessRule] Get()
    {
        return [AzDoProcessRule]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProcessName      = $CurrentResourceObject.ProcessName
        $properties.WorkItemTypeName = $CurrentResourceObject.WorkItemTypeName
        $properties.RuleName         = $CurrentResourceObject.RuleName
        $properties.Conditions       = $CurrentResourceObject.Conditions
        $properties.Actions          = $CurrentResourceObject.Actions
        $properties.IsDisabled       = $CurrentResourceObject.IsDisabled
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoProcessRule] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
