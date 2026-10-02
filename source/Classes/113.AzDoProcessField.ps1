<#
.SYNOPSIS
    DSC resource for managing fields on a work item type of an Azure DevOps inherited process.

.DESCRIPTION
    Manages a field on a work item type: adding a new custom field, attaching an existing field
    (including a system field such as System.Priority), and the per-type settings - required,
    default value and read-only.

.NOTES
    Author: Michael Zanatta

    A field has two levels of existence, and this resource manages the second. The field definition
    is organization-scoped and shared: its name and type belong to the organization, and changing
    them would change the field everywhere it is used. What is per-work-item-type is whether the
    field is required, its default value and whether it is read-only, and those are what this
    resource reconciles.

    A new custom field's reference name is assigned by Azure DevOps from its display name and
    cannot be chosen, so the resource matches by display name and reads the reference name back.

    Removing a field from a work item type is not the same as deleting the field. The definition
    survives in the organization and the data already stored on existing work items is retained,
    just no longer shown.

.PARAMETER ProcessName
    The name of the inherited process.

.PARAMETER WorkItemTypeName
    The display name of the work item type.

.PARAMETER FieldName
    The display name of the field.

.PARAMETER FieldReferenceName
    The reference name of an existing field to attach, for example 'System.Priority'. Omit when
    creating a new custom field.

.PARAMETER FieldType
    The field type for a new custom field: 'string', 'integer', 'boolean', 'dateTime', 'html',
    'picklistString', 'picklistInteger', 'identity', 'double', 'plainText' or 'treePath'.

.PARAMETER PicklistName
    The name of the picklist backing a picklist-typed field. Declare it with AzDoPicklist and use
    DependsOn.

.PARAMETER IsRequired
    Whether the field is required on this work item type.

.PARAMETER DefaultValue
    The default value for the field on this work item type.

.PARAMETER ReadOnly
    Whether the field is read-only on this work item type.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoProcessField Severity
    {
        ProcessName      = 'Contoso Agile'
        WorkItemTypeName = 'Incident'
        FieldName        = 'Severity'
        FieldType        = 'picklistString'
        PicklistName     = 'Severity'
        IsRequired       = $true
        Ensure           = 'Present'
    }
#>

[DscResource()]
class AzDoProcessField : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Process')]
    [System.String]$ProcessName

    [DscProperty(Mandatory)]
    [Alias('WorkItemType')]
    [System.String]$WorkItemTypeName

    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$FieldName

    [DscProperty()]
    [System.String]$FieldReferenceName

    [DscProperty()]
    [ValidateSet('string', 'integer', 'boolean', 'dateTime', 'html', 'picklistString', 'picklistInteger', 'identity', 'double', 'plainText', 'treePath')]
    [System.String]$FieldType = 'string'

    [DscProperty()]
    [System.String]$PicklistName

    [DscProperty()]
    [System.Boolean]$IsRequired = $false

    [DscProperty()]
    [System.String]$DefaultValue

    [DscProperty()]
    [System.Boolean]$ReadOnly = $false

    AzDoProcessField()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoProcessField] Get()
    {
        return [AzDoProcessField]$($this.GetDscCurrentStateProperties())
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

        $properties.ProcessName        = $CurrentResourceObject.ProcessName
        $properties.WorkItemTypeName   = $CurrentResourceObject.WorkItemTypeName
        $properties.FieldName          = $CurrentResourceObject.FieldName
        $properties.FieldReferenceName = $CurrentResourceObject.FieldReferenceName
        $properties.FieldType          = $CurrentResourceObject.FieldType
        $properties.PicklistName       = $CurrentResourceObject.PicklistName
        $properties.IsRequired         = $CurrentResourceObject.IsRequired
        $properties.DefaultValue       = $CurrentResourceObject.DefaultValue
        $properties.ReadOnly           = $CurrentResourceObject.ReadOnly
        $properties.LookupResult       = $CurrentResourceObject.LookupResult
        $properties.Ensure             = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoProcessField] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
