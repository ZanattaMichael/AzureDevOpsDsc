<#
.SYNOPSIS
Adds a field to an Azure DevOps work item type.

.DESCRIPTION
Creates a new custom field on the work item type, or attaches an existing field when
FieldReferenceName is supplied.

A picklist-typed field needs a picklist to point at, so PicklistName is resolved to its id before
the field is created - and the failure to resolve it is reported rather than creating a
picklist-typed field with no list.

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
New-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity' -FieldType 'picklistString' -PicklistName 'Severity'
#>
Function New-AzDoProcessField
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

    Write-Verbose "[New-AzDoProcessField] Started."

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
        Write-Error "[New-AzDoProcessField] Work item type '$WorkItemTypeName' was not found on process '$ProcessName'."
        return
    }

    $params = @{
        Organization        = $OrganizationName
        ProcessId           = $processId
        WorkItemTypeRefName = $refName
        FieldName           = $FieldName
        FieldType           = $FieldType
        IsRequired          = [bool]$IsRequired
        ReadOnly            = [bool]$ReadOnly
    }

    if (-not [String]::IsNullOrWhiteSpace($FieldReferenceName)) { $params.FieldReferenceName = $FieldReferenceName }
    if ($PSBoundParameters.ContainsKey('DefaultValue'))         { $params.DefaultValue = $DefaultValue }

    # A picklist-typed field is meaningless without its list, so resolve it before creating
    # anything rather than leaving a field pointing at nothing.
    if (-not [String]::IsNullOrWhiteSpace($PicklistName))
    {
        $picklists  = List-DevOpsPicklists -Organization $OrganizationName
        $picklistId = ($picklists | Where-Object { $_.name -eq $PicklistName } | Select-Object -First 1).id

        if ([String]::IsNullOrWhiteSpace($picklistId))
        {
            Write-Error "[New-AzDoProcessField] Picklist '$PicklistName' was not found, so field '$FieldName' has not been created. Declare it with AzDoPicklist and use DependsOn."
            return
        }

        $params.PicklistId = $picklistId
    }

    Write-Verbose "[New-AzDoProcessField] Adding field '$FieldName' to work item type '$WorkItemTypeName'."

    $created = Add-DevOpsProcessField @params

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoProcessField] Failed to add field '$FieldName' to work item type '$WorkItemTypeName'."
        return
    }

    return $created
}
