<#
.SYNOPSIS
Updates a work item type on an inherited process.

.DESCRIPTION
PATCHes a work item type's description, colour, icon or disabled state.

Updating an inherited work item type turns its customization from 'system' to 'inherited'. That is
not reversible through this endpoint - reverting a customized inherited type to its parent's
definition needs a separate delete call, which is why the resource does not attempt it.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type, for example 'MyProcess.Incident'.

.PARAMETER Description
A description for the work item type.

.PARAMETER Color
The hex colour, without a leading '#'.

.PARAMETER Icon
The icon name.

.PARAMETER IsDisabled
Whether the work item type is disabled.

.EXAMPLE
Update-DevOpsProcessWorkItemType -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'MyProcess.Incident' -Color 'FF0000'
#>
Function Update-DevOpsProcessWorkItemType
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
        [AllowEmptyString()]
        [String]$Description,

        [Parameter()]
        [String]$Color,

        [Parameter()]
        [String]$Icon,

        [Parameter()]
        [Object]$IsDisabled,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypes/{2}?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    # Only send what the caller supplied, so updating a colour does not blank a description.
    $body = @{}
    if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }
    if ($PSBoundParameters.ContainsKey('Color'))       { $body.color = $Color }
    if ($PSBoundParameters.ContainsKey('Icon'))        { $body.icon = $Icon }
    if ($PSBoundParameters.ContainsKey('IsDisabled'))  { $body.isDisabled = [bool]$IsDisabled }

    if ($body.Keys.Count -eq 0)
    {
        Write-Verbose "[Update-DevOpsProcessWorkItemType] No updatable values supplied for '$WorkItemTypeRefName'. No action taken."
        return $null
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[Update-DevOpsProcessWorkItemType] Failed to update work item type '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
