<#
.SYNOPSIS
Removes a field from a work item type.

.DESCRIPTION
Detaches the field from the work item type. The field definition itself remains in the
organization and any data already stored in it on existing work items is retained but no longer
shown - removing a field from a type is not the same as deleting the field.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER FieldReferenceName
The reference name of the field to remove.

.EXAMPLE
Remove-DevOpsProcessField -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -FieldReferenceName 'Custom.Severity'
#>
Function Remove-DevOpsProcessField
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
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/fields/{3}?api-version={4}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $FieldReferenceName, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsProcessField] Failed to remove field '$FieldReferenceName' from '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
