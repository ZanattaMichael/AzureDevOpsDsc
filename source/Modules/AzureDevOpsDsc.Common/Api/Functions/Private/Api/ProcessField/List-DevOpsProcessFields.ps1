<#
.SYNOPSIS
Lists the fields on a work item type of an inherited process.

.DESCRIPTION
Returns the fields the work item type exposes, with their per-type settings - required, default
value, and the customization that placed them there.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.EXAMPLE
List-DevOpsProcessFields -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident'
#>
Function List-DevOpsProcessFields
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProcessId,

        [Parameter(Mandatory = $true)]
        [String]$WorkItemTypeRefName,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/fields?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsProcessFields] Failed to list fields for work item type '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
