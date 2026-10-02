<#
.SYNOPSIS
Creates a custom work item type on an Azure DevOps inherited process.

.DESCRIPTION
Adds a new work item type to the process.

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
New-AzDoProcessWorkItemType -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -Color 'F6546A'
#>
Function New-AzDoProcessWorkItemType
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

    Write-Verbose "[New-AzDoProcessWorkItemType] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId

    if ([String]::IsNullOrWhiteSpace($processId))
    {
        $resolved  = Resolve-AzDoProcessWorkItemType -Organization $OrganizationName -ProcessName $ProcessName
        $processId = $resolved.Process.id

        if (-not $resolved.IsCustomizable)
        {
            Write-Error "[New-AzDoProcessWorkItemType] Process '$ProcessName' cannot be customized ($($resolved.Reason))."
            return
        }
    }

    if ([String]::IsNullOrWhiteSpace($processId))
    {
        Write-Error "[New-AzDoProcessWorkItemType] Process '$ProcessName' was not found."
        return
    }

    $params = @{
        Organization = $OrganizationName
        ProcessId    = $processId
        Name         = $WorkItemTypeName
        IsDisabled   = [bool]$IsDisabled
    }

    if ($PSBoundParameters.ContainsKey('Description'))                   { $params.Description = $Description }
    if (-not [String]::IsNullOrWhiteSpace($Color))                       { $params.Color = $Color.TrimStart('#') }
    if (-not [String]::IsNullOrWhiteSpace($Icon))                        { $params.Icon = $Icon }

    Write-Verbose "[New-AzDoProcessWorkItemType] Creating work item type '$WorkItemTypeName' on process '$ProcessName'."

    $created = New-DevOpsProcessWorkItemType @params

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoProcessWorkItemType] Failed to create work item type '$WorkItemTypeName' on process '$ProcessName'."
        return
    }

    return $created
}
