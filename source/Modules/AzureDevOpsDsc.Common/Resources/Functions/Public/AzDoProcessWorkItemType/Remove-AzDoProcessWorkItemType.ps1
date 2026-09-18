<#
.SYNOPSIS
Removes a work item type from an Azure DevOps inherited process.

.DESCRIPTION
Removal means different things for the two kinds of work item type, and both are destructive:

- A custom type is deleted, along with every work item of that type in every project using the
  process.
- An inherited type is reverted to its parent's definition, discarding this process's
  customizations.

Neither can be undone, so both require AllowDestructiveRemove. Disabling the type with
IsDisabled is the reversible alternative and is usually what is actually wanted.

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
Remove-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -AllowDestructiveRemove $true
#>
Function Remove-AzDoProcessWorkItemType
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

    Write-Verbose "[Remove-AzDoProcessWorkItemType] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $customization    = $LookupResult.customization

    if ([String]::IsNullOrWhiteSpace($processId) -or [String]::IsNullOrWhiteSpace($refName))
    {
        $resolved      = Resolve-AzDoProcessWorkItemType -Organization $OrganizationName -ProcessName $ProcessName -WorkItemTypeName $WorkItemTypeName
        $processId     = $resolved.Process.id
        $refName       = $resolved.WorkItemType.referenceName
        $customization = $resolved.WorkItemType.customization
    }

    if ([String]::IsNullOrWhiteSpace($refName))
    {
        Write-Verbose "[Remove-AzDoProcessWorkItemType] Work item type '$WorkItemTypeName' does not exist on process '$ProcessName'. Nothing to remove."
        return
    }

    if (-not $AllowDestructiveRemove)
    {
        $consequence = if ($customization -eq 'custom')
        {
            "deleting it would delete every work item of type '$WorkItemTypeName' in every project using process '$ProcessName'"
        }
        else
        {
            "it is inherited from the parent process, so removing it would discard this process's customizations and revert it to the parent definition"
        }

        Write-Error "[Remove-AzDoProcessWorkItemType] Refusing to remove work item type '$WorkItemTypeName': $consequence. Set AllowDestructiveRemove = \$true to permit this, or set IsDisabled = \$true to hide the type reversibly instead."
        return
    }

    Write-Warning "[Remove-AzDoProcessWorkItemType] Removing work item type '$WorkItemTypeName' from process '$ProcessName'. This cannot be undone."

    return (Remove-DevOpsProcessWorkItemType -Organization $OrganizationName -ProcessId $processId -WorkItemTypeRefName $refName)
}
