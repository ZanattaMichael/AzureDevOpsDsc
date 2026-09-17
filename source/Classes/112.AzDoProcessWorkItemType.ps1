<#
.SYNOPSIS
    DSC resource for managing work item types on an Azure DevOps inherited process.

.DESCRIPTION
    Manages a work item type on an inherited process - either a custom type added to the process,
    or the customizable properties (description, colour, icon, disabled state) of a type inherited
    from the parent process.

.NOTES
    Author: Michael Zanatta

    Only inherited processes can be customized. The system processes - Agile, Scrum, Basic and CMMI
    - are read-only, and the resource reports that rather than letting the API return an opaque
    error. Create an inherited process with AzDoProcess first and customize that.

    Customizing an inherited work item type changes its 'customization' from 'system' to
    'inherited'. This is a one-way change through the update endpoint; reverting to the parent's
    definition is a delete, which the resource performs only when Ensure is 'Absent'.

    Removal means different things for the two kinds of type, and both are destructive:
    for a custom type it deletes the type and every work item of that type in every project using
    the process; for an inherited type it discards this process's customizations and reverts to the
    parent. The resource requires AllowDestructiveRemove for either.

.PARAMETER ProcessName
    The name of the inherited process.

.PARAMETER WorkItemTypeName
    The display name of the work item type, for example 'Incident'.

.PARAMETER Description
    A description for the work item type.

.PARAMETER Color
    The hex colour without a leading '#', for example 'F6546A'.

.PARAMETER Icon
    The icon name, for example 'icon_book' or 'icon_flame'.

.PARAMETER IsDisabled
    Whether the work item type is disabled - hidden from pickers without being deleted. Disabling
    is the reversible alternative to removal.

.PARAMETER AllowDestructiveRemove
    Required for Ensure = 'Absent'. Removing a custom work item type deletes every work item of
    that type.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoProcessWorkItemType Incident
    {
        ProcessName      = 'Contoso Agile'
        WorkItemTypeName = 'Incident'
        Description      = 'A production incident'
        Color            = 'F6546A'
        Icon             = 'icon_flame'
        Ensure           = 'Present'
    }
#>

[DscResource()]
class AzDoProcessWorkItemType : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Process')]
    [System.String]$ProcessName

    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$WorkItemTypeName

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.String]$Color

    [DscProperty()]
    [System.String]$Icon

    [DscProperty()]
    [System.Boolean]$IsDisabled = $false

    [DscProperty()]
    [System.Boolean]$AllowDestructiveRemove = $false

    AzDoProcessWorkItemType()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoProcessWorkItemType] Get()
    {
        return [AzDoProcessWorkItemType]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProcessName            = $CurrentResourceObject.ProcessName
        $properties.WorkItemTypeName       = $CurrentResourceObject.WorkItemTypeName
        $properties.Description            = $CurrentResourceObject.Description
        $properties.Color                  = $CurrentResourceObject.Color
        $properties.Icon                   = $CurrentResourceObject.Icon
        $properties.IsDisabled             = $CurrentResourceObject.IsDisabled
        $properties.AllowDestructiveRemove = $CurrentResourceObject.AllowDestructiveRemove
        $properties.LookupResult           = $CurrentResourceObject.LookupResult
        $properties.Ensure                 = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoProcessWorkItemType] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
