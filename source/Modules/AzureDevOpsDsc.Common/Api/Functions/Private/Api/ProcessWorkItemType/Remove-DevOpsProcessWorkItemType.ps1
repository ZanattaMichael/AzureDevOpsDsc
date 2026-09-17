<#
.SYNOPSIS
Deletes a work item type from an inherited process.

.DESCRIPTION
Deletes a custom work item type, or - for an inherited one - reverts it to its parent's
definition, discarding the customizations made to it on this process.

Deleting a custom work item type destroys every work item of that type in every project using the
process. There is no undo.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.EXAMPLE
Remove-DevOpsProcessWorkItemType -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'MyProcess.Incident'
#>
Function Remove-DevOpsProcessWorkItemType
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

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypes/{2}?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsProcessWorkItemType] Failed to delete work item type '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
