<#
.SYNOPSIS
Associates a work item type with a behavior (backlog level).

.DESCRIPTION
Adds the behavior association that makes a work item type appear on a backlog. Without it a custom
type exists but shows up on no backlog, which is the usual reason a newly created type seems to do
nothing.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER BehaviorRefName
The reference name of the behavior, for example 'System.RequirementBacklogBehavior'.

.PARAMETER IsDefault
Whether this type is the default for creating new items at that backlog level.

.EXAMPLE
Add-DevOpsWorkItemTypeBehavior -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -BehaviorRefName 'System.RequirementBacklogBehavior'
#>
Function Add-DevOpsWorkItemTypeBehavior
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
        [String]$BehaviorRefName,

        [Parameter()]
        [Boolean]$IsDefault = $false,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypesbehaviors/{2}/behaviors?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    $body = @{
        behavior  = @{ id = $BehaviorRefName }
        isDefault = $IsDefault
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[Add-DevOpsWorkItemTypeBehavior] Failed to associate '$WorkItemTypeRefName' with behavior '$BehaviorRefName'. Error: $_"
        return $null
    }
}
