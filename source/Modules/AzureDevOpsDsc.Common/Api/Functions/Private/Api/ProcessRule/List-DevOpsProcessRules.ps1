<#
.SYNOPSIS
Lists the rules on a work item type of an inherited process.

.DESCRIPTION
Returns the conditional rules defined on the work item type. Each rule carries its conditions
(when to apply) and actions (what to do), plus a name and a disabled flag.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.EXAMPLE
List-DevOpsProcessRules -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident'
#>
Function List-DevOpsProcessRules
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

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/rules?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsProcessRules] Failed to list rules for work item type '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
