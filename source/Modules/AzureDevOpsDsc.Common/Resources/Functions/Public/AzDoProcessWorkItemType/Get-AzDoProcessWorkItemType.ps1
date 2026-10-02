<#
.SYNOPSIS
Retrieves the current state of a work item type on an Azure DevOps inherited process.

.DESCRIPTION
Resolves the process and the work item type, then compares the customizable properties against the
desired state.

Only inherited processes can be customized. When the configuration names a system process (Agile,
Scrum, Basic, CMMI) this reports why rather than letting the API return an opaque error at apply
time.

Colour comparison ignores a leading '#' and is case-insensitive, since the API returns a bare
uppercase hex value and configurations are written either way.

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
Get-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident'
#>
Function Get-AzDoProcessWorkItemType
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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

    Write-Verbose "[Get-AzDoProcessWorkItemType] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $result = @{
        Ensure            = [Ensure]::Absent
        ProcessName       = $ProcessName
        WorkItemTypeName  = $WorkItemTypeName
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $resolved = Resolve-AzDoProcessWorkItemType -Organization $OrganizationName -ProcessName $ProcessName -WorkItemTypeName $WorkItemTypeName

    if ($resolved.Reason -eq 'ProcessNotFound')
    {
        Write-Error "[Get-AzDoProcessWorkItemType] Process '$ProcessName' was not found."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'ProcessNotFound'
        return $result
    }

    if ($resolved.Reason -eq 'ProcessNotCustomizable')
    {
        Write-Error "[Get-AzDoProcessWorkItemType] Process '$ProcessName' is a system process and cannot be customized. Create an inherited process with AzDoProcess and customize that instead."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'ProcessNotCustomizable'
        return $result
    }

    if ($resolved.Reason -eq 'ProcessDetailLookupFailed' -or $resolved.Reason -eq 'WorkItemTypeLookupFailed')
    {
        Write-Error "[Get-AzDoProcessWorkItemType] Could not read process '$ProcessName' ($($resolved.Reason))."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = $resolved.Reason
        return $result
    }

    $result.processId = $resolved.Process.id

    if ($null -eq $resolved.WorkItemType)
    {
        Write-Verbose "[Get-AzDoProcessWorkItemType] Work item type '$WorkItemTypeName' does not exist on process '$ProcessName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $workItemType = $resolved.WorkItemType

    $result.workItemTypeRefName = $workItemType.referenceName
    $result.customization       = $workItemType.customization
    $result.liveCache           = $workItemType
    $result.Ensure              = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $currentDescription = if ($null -eq $workItemType.description) { '' } else { [string]$workItemType.description }

        if ($Description.Trim() -ne $currentDescription.Trim())
        {
            Write-Verbose "[Get-AzDoProcessWorkItemType] Description differs for '$WorkItemTypeName'."
            $propertiesChanged += 'Description'
        }
    }

    if ($PSBoundParameters.ContainsKey('Color') -and (-not [String]::IsNullOrWhiteSpace($Color)))
    {
        # The API returns a bare uppercase hex value; configurations are written with or without
        # the leading '#' and in either case.
        $desiredColor = $Color.TrimStart('#')
        $currentColor = "$($workItemType.color)".TrimStart('#')

        if ($desiredColor -ne $currentColor)
        {
            Write-Verbose "[Get-AzDoProcessWorkItemType] Color differs for '$WorkItemTypeName'."
            $propertiesChanged += 'Color'
        }
    }

    if ($PSBoundParameters.ContainsKey('Icon') -and (-not [String]::IsNullOrWhiteSpace($Icon)))
    {
        if ($Icon -ne "$($workItemType.icon)")
        {
            Write-Verbose "[Get-AzDoProcessWorkItemType] Icon differs for '$WorkItemTypeName'."
            $propertiesChanged += 'Icon'
        }
    }

    if ($PSBoundParameters.ContainsKey('IsDisabled'))
    {
        if ([bool]$workItemType.isDisabled -ne $IsDisabled)
        {
            Write-Verbose "[Get-AzDoProcessWorkItemType] IsDisabled differs for '$WorkItemTypeName'."
            $propertiesChanged += 'IsDisabled'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoProcessWorkItemType] '$WorkItemTypeName' status: $($result.status)."

    return $result
}
