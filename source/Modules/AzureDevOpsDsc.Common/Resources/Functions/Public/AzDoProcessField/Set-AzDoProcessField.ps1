<#
.SYNOPSIS
Updates a field's settings on an Azure DevOps work item type.

.DESCRIPTION
Applies the per-work-item-type settings: required, default value and read-only.

The field's name and type are not changed here. They belong to the organization-scoped field
definition and are shared by every work item type using the field, so changing them from one type's
configuration would change the field everywhere it is used.

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
Set-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity' -IsRequired $true
#>
Function Set-AzDoProcessField
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

    Write-Verbose "[Set-AzDoProcessField] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $fieldRefName     = $LookupResult.fieldReferenceName

    if ([String]::IsNullOrWhiteSpace($fieldRefName))
    {
        Write-Error "[Set-AzDoProcessField] Field '$FieldName' was not found on work item type '$WorkItemTypeName'."
        return
    }

    $params = @{
        Organization        = $OrganizationName
        ProcessId           = $processId
        WorkItemTypeRefName = $refName
        FieldReferenceName  = $fieldRefName
    }

    if ($PSBoundParameters.ContainsKey('IsRequired'))   { $params.IsRequired = [bool]$IsRequired }
    if ($PSBoundParameters.ContainsKey('ReadOnly'))     { $params.ReadOnly = [bool]$ReadOnly }
    if ($PSBoundParameters.ContainsKey('DefaultValue')) { $params.DefaultValue = $DefaultValue }

    Write-Verbose "[Set-AzDoProcessField] Updating field '$FieldName' on work item type '$WorkItemTypeName'."

    return (Update-DevOpsProcessField @params)
}
