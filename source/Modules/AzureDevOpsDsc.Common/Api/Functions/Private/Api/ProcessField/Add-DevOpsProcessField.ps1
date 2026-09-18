<#
.SYNOPSIS
Adds a field to a work item type on an inherited process.

.DESCRIPTION
Adds a field to a work item type. The same endpoint both creates a brand-new custom field and
attaches an existing one - including a system field such as System.Priority - to the type, which
is why one function covers both.

A new custom field's reference name is assigned by Azure DevOps from the display name; it cannot
be chosen. Callers therefore match fields by display name and read the reference name back.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER FieldName
The display name of the field.

.PARAMETER FieldReferenceName
The reference name of an existing field to attach. Omit when creating a new field.

.PARAMETER FieldType
The field type: 'string', 'integer', 'boolean', 'dateTime', 'html', 'picklistString',
'picklistInteger', 'identity', 'double', 'plainText' or 'treePath'.

.PARAMETER IsRequired
Whether the field is required on this work item type.

.PARAMETER DefaultValue
The default value for the field on this work item type.

.PARAMETER PicklistId
The id of the picklist backing a picklist-typed field.

.PARAMETER ReadOnly
Whether the field is read-only on this work item type.

.EXAMPLE
Add-DevOpsProcessField -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -FieldName 'Severity' -FieldType 'picklistString' -PicklistId $listId
#>
Function Add-DevOpsProcessField
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
        [String]$FieldName,

        [Parameter()]
        [String]$FieldReferenceName,

        [Parameter()]
        [String]$FieldType = 'string',

        [Parameter()]
        [Boolean]$IsRequired = $false,

        [Parameter()]
        [AllowEmptyString()]
        [String]$DefaultValue,

        [Parameter()]
        [String]$PicklistId,

        [Parameter()]
        [Boolean]$ReadOnly = $false,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/fields?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    $body = @{
        name       = $FieldName
        type       = $FieldType
        required   = $IsRequired
        readOnly   = $ReadOnly
    }

    # Attaching an existing field is addressed by reference name; creating a new one is not, since
    # Azure DevOps assigns the reference name itself.
    if (-not [String]::IsNullOrWhiteSpace($FieldReferenceName)) { $body.referenceName = $FieldReferenceName }
    if (-not [String]::IsNullOrWhiteSpace($PicklistId))         { $body.pickList = @{ id = $PicklistId } }
    if ($PSBoundParameters.ContainsKey('DefaultValue'))         { $body.defaultValue = $DefaultValue }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[Add-DevOpsProcessField] Failed to add field '$FieldName' to work item type '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
