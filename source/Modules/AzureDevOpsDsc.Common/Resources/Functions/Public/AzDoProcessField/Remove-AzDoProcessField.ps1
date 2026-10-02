<#
.SYNOPSIS
Removes a field from an Azure DevOps work item type.

.DESCRIPTION
Detaches the field from the work item type. This is not the same as deleting the field: the
definition survives in the organization and the data already stored on existing work items is
retained, just no longer shown - so the operation is reversible by re-adding the field.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER WorkItemTypeName
The display name of the work item type.

.PARAMETER FieldName
The display name of the field.

.PARAMETER FieldReferenceName
The reference name of an existing field to attach.

.PARAMETER FieldType
The field type for a new custom field.

.PARAMETER PicklistName
The name of the picklist backing a picklist-typed field.

.PARAMETER IsRequired
Whether the field is required on this work item type.

.PARAMETER DefaultValue
The default value on this work item type.

.PARAMETER ReadOnly
Whether the field is read-only on this work item type.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity'
#>
Function Remove-AzDoProcessField
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
        [System.String]$FieldName,

        [Parameter()]
        [System.String]$FieldReferenceName,

        [Parameter()]
        [System.String]$FieldType = 'string',

        [Parameter()]
        [System.String]$PicklistName,

        [Parameter()]
        [System.Boolean]$IsRequired,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]$DefaultValue,

        [Parameter()]
        [System.Boolean]$ReadOnly,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoProcessField] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $fieldRefName     = $LookupResult.fieldReferenceName

    if ([String]::IsNullOrWhiteSpace($fieldRefName))
    {
        Write-Verbose "[Remove-AzDoProcessField] Field '$FieldName' is not on work item type '$WorkItemTypeName'. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoProcessField] Removing field '$FieldName' from work item type '$WorkItemTypeName'."

    return (Remove-DevOpsProcessField -Organization $OrganizationName -ProcessId $processId `
        -WorkItemTypeRefName $refName -FieldReferenceName $fieldRefName)
}
