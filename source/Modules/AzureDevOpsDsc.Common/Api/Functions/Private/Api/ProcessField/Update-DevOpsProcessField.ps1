<#
.SYNOPSIS
Updates a field's settings on a work item type.

.DESCRIPTION
PATCHes the per-work-item-type settings of a field: whether it is required, its default value and
whether it is read-only. The field's own definition - its name and type - is organization-scoped
and is not changed here.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER FieldReferenceName
The reference name of the field.

.PARAMETER IsRequired
Whether the field is required on this work item type.

.PARAMETER DefaultValue
The default value for the field on this work item type.

.PARAMETER ReadOnly
Whether the field is read-only on this work item type.

.EXAMPLE
Update-DevOpsProcessField -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -FieldReferenceName 'Custom.Severity' -IsRequired $true
#>
Function Update-DevOpsProcessField
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
        [String]$FieldReferenceName,

        [Parameter()]
        [Object]$IsRequired,

        [Parameter()]
        [AllowEmptyString()]
        [String]$DefaultValue,

        [Parameter()]
        [Object]$ReadOnly,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/fields/{3}?api-version={4}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $FieldReferenceName, $ApiVersion

    $body = @{ referenceName = $FieldReferenceName }

    if ($PSBoundParameters.ContainsKey('IsRequired'))   { $body.required = [bool]$IsRequired }
    if ($PSBoundParameters.ContainsKey('ReadOnly'))     { $body.readOnly = [bool]$ReadOnly }
    if ($PSBoundParameters.ContainsKey('DefaultValue')) { $body.defaultValue = $DefaultValue }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[Update-DevOpsProcessField] Failed to update field '$FieldReferenceName' on '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
