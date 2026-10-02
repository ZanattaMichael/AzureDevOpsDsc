<#
.SYNOPSIS
Retrieves the current state of a field on an Azure DevOps work item type.

.DESCRIPTION
Resolves the process and work item type, finds the field, and compares the per-work-item-type
settings - required, default value, read-only - against the desired state.

The field's own name and type are organization-scoped and shared across every work item type using
the field, so they are not reconciled here: changing them would change the field everywhere.

Fields are matched by display name or reference name, because a new custom field's reference name
is assigned by Azure DevOps and cannot be predicted from the configuration.

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
Get-AzDoProcessField -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -FieldName 'Severity'
#>
Function Get-AzDoProcessField
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

    Write-Verbose "[Get-AzDoProcessField] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $result = @{
        Ensure            = [Ensure]::Absent
        ProcessName       = $ProcessName
        WorkItemTypeName  = $WorkItemTypeName
        FieldName         = $FieldName
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $resolved = Resolve-AzDoProcessWorkItemType -Organization $OrganizationName -ProcessName $ProcessName -WorkItemTypeName $WorkItemTypeName

    if (-not $resolved.IsCustomizable -or $null -eq $resolved.WorkItemType)
    {
        Write-Error "[Get-AzDoProcessField] Cannot read fields for '$WorkItemTypeName' on process '$ProcessName' ($($resolved.Reason))."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = $resolved.Reason
        return $result
    }

    $processId = $resolved.Process.id
    $refName   = $resolved.WorkItemType.referenceName

    $result.processId           = $processId
    $result.workItemTypeRefName = $refName

    $fields = List-DevOpsProcessFields -Organization $OrganizationName -ProcessId $processId -WorkItemTypeRefName $refName

    # A new custom field's reference name is assigned by Azure DevOps, so a configuration can only
    # name the field by its display name until it exists.
    $field = $fields | Where-Object {
        ($_.name -eq $FieldName) -or
        ((-not [String]::IsNullOrWhiteSpace($FieldReferenceName)) -and $_.referenceName -eq $FieldReferenceName)
    } | Select-Object -First 1

    if ($null -eq $field)
    {
        Write-Verbose "[Get-AzDoProcessField] Field '$FieldName' is not on work item type '$WorkItemTypeName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.fieldReferenceName = $field.referenceName
    $result.liveCache          = $field
    $result.Ensure             = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('IsRequired'))
    {
        if ([bool]$field.required -ne $IsRequired)
        {
            Write-Verbose "[Get-AzDoProcessField] IsRequired differs for field '$FieldName'."
            $propertiesChanged += 'IsRequired'
        }
    }

    if ($PSBoundParameters.ContainsKey('ReadOnly'))
    {
        if ([bool]$field.readOnly -ne $ReadOnly)
        {
            Write-Verbose "[Get-AzDoProcessField] ReadOnly differs for field '$FieldName'."
            $propertiesChanged += 'ReadOnly'
        }
    }

    if ($PSBoundParameters.ContainsKey('DefaultValue'))
    {
        $currentDefault = if ($null -eq $field.defaultValue) { '' } else { [string]$field.defaultValue }

        if ("$DefaultValue" -ne $currentDefault)
        {
            Write-Verbose "[Get-AzDoProcessField] DefaultValue differs for field '$FieldName'."
            $propertiesChanged += 'DefaultValue'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoProcessField] Field '$FieldName' status: $($result.status)."

    return $result
}
