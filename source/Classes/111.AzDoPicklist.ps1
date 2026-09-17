<#
.SYNOPSIS
    DSC resource for managing Azure DevOps picklists.

.DESCRIPTION
    Manages a picklist - the set of allowed values behind a custom field of type "picklist".

.NOTES
    Author: Michael Zanatta

    Picklists are organization-scoped, not process-scoped. One picklist can back fields in several
    processes, so changing it changes every field that uses it.

    Items are replaced wholesale, because the API takes the complete list on update. Removing an
    item that work items already carry does not rewrite those work items: they keep the value, and
    it then fails validation the next time somebody edits them. Narrowing a picklist is therefore
    worth doing deliberately rather than as a side effect of tidying a configuration.

    Item order is preserved as written, since it is the order shown in the picker.

.PARAMETER PicklistName
    The name of the picklist.

.PARAMETER Items
    The complete set of allowed values, in the order they should appear.

.PARAMETER PicklistType
    'String' or 'Integer'. Defaults to 'String'. The type is fixed at creation - changing it
    requires recreating the picklist, which this resource does not do implicitly.

.PARAMETER IsSuggested
    When true the list is a suggestion rather than a closed set, and users may enter values that
    are not on it.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoPicklist Severity
    {
        PicklistName = 'Severity'
        Items        = @('1 - Critical', '2 - High', '3 - Medium', '4 - Low')
        Ensure       = 'Present'
    }
#>

[DscResource()]
class AzDoPicklist : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$PicklistName

    [DscProperty()]
    [System.String[]]$Items

    [DscProperty()]
    [ValidateSet('String', 'Integer')]
    [System.String]$PicklistType = 'String'

    [DscProperty()]
    [System.Boolean]$IsSuggested = $false

    AzDoPicklist()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoPicklist] Get()
    {
        return [AzDoPicklist]$($this.GetDscCurrentStateProperties())
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

        $properties.PicklistName = $CurrentResourceObject.PicklistName
        $properties.Items        = $CurrentResourceObject.Items
        $properties.PicklistType = $CurrentResourceObject.PicklistType
        $properties.IsSuggested  = $CurrentResourceObject.IsSuggested
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoPicklist] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
