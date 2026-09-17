<#
.SYNOPSIS
Updates a work item type on an Azure DevOps inherited process.

.DESCRIPTION
Applies the configured description, colour, icon and disabled state.

Updating a work item type inherited from the parent process changes its customization from
'system' to 'inherited'. That is a one-way change through this endpoint - reverting to the parent's
definition is a delete, which this resource performs only when Ensure is 'Absent'.

Only the properties the configuration states are sent, so setting a colour does not blank a
description somebody wrote in the UI.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER WorkItemTypeName
The display name of the work item type.

.PARAMETER Description
A description for the work item type.

.PARAMETER Color
The hex colour without a leading '#'.

.PARAMETER Icon
The icon name.

.PARAMETER IsDisabled
Whether the work item type is disabled.

.PARAMETER AllowDestructiveRemove
Required for removal, which deletes work items or discards customizations.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -Color 'FF0000'
#>
Function Set-AzDoProcessWorkItemType
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Process')]
        [System.String]$ProcessName,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$WorkItemTypeName,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]$Description,

        [Parameter()]
        [System.String]$Color,

        [Parameter()]
        [System.String]$Icon,

        [Parameter()]
        [System.Boolean]$IsDisabled,

        [Parameter()]
        [System.Boolean]$AllowDestructiveRemove,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoProcessWorkItemType] Started."

    if ($LookupResult.reason -in @('ProcessNotCustomizable', 'ProcessNotFound'))
    {
        Write-Error "[Set-AzDoProcessWorkItemType] Cannot customize process '$ProcessName' ($($LookupResult.reason)). No change was made."
        return
    }

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
        Write-Error "[Set-AzDoProcessWorkItemType] Work item type '$WorkItemTypeName' was not found on process '$ProcessName'."
        return
    }

    $params = @{
        Organization        = $OrganizationName
        ProcessId           = $processId
        WorkItemTypeRefName = $refName
    }

    if ($PSBoundParameters.ContainsKey('Description'))  { $params.Description = $Description }
    if (-not [String]::IsNullOrWhiteSpace($Color))      { $params.Color = $Color.TrimStart('#') }
    if (-not [String]::IsNullOrWhiteSpace($Icon))       { $params.Icon = $Icon }
    if ($PSBoundParameters.ContainsKey('IsDisabled'))   { $params.IsDisabled = [bool]$IsDisabled }

    Write-Verbose "[Set-AzDoProcessWorkItemType] Updating work item type '$WorkItemTypeName'."

    return (Update-DevOpsProcessWorkItemType @params)
}
