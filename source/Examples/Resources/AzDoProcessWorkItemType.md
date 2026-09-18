# DSC AzDoProcessWorkItemType Resource

## Syntax

```PowerShell
AzDoProcessWorkItemType [string] #ResourceName
{
    ProcessName                = [String]$ProcessName
    WorkItemTypeName           = [String]$WorkItemTypeName
    [ Description              = [String]$Description ]
    [ Color                    = [String]$Color ]
    [ Icon                     = [String]$Icon ]
    [ IsDisabled               = [Boolean]$IsDisabled ]
    [ AllowDestructiveRemove   = [Boolean]$AllowDestructiveRemove ]
    [ Ensure                   = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProcessName**: The name of the inherited process. Mandatory.
- **WorkItemTypeName**: The display name of the work item type, for example `Incident`. This is the key property.
- **Description**: A description for the work item type.
- **Color**: The hex colour, with or without a leading `#`, for example `F6546A`.
- **Icon**: The icon name, for example `icon_book` or `icon_flame`.
- **IsDisabled**: Hides the type from pickers without deleting it — the reversible alternative to removal.
- **AllowDestructiveRemove**: Required for `Ensure = 'Absent'`.
- **Ensure**: Whether the work item type should exist on the process.

## Additional Information

Manages either a **custom** work item type added to an inherited process, or the customizable properties of a type **inherited** from the parent process.

### Only inherited processes can be customized

The system processes — Agile, Scrum, Basic and CMMI — are read-only. Naming one is reported with that reason rather than being allowed to fail against the API with an opaque error. Create an inherited process with `AzDoProcess` and customize that.

### Customizing an inherited type is one-way

Updating a type inherited from the parent changes its `customization` from `system` to `inherited`. Reverting to the parent's definition is a *delete*, not an update, which this resource performs only when `Ensure = 'Absent'`.

### Removal means two different things, both destructive

- A **custom** type: deleted, along with every work item of that type in every project using the process.
- An **inherited** type: reverted to the parent's definition, discarding this process's customizations.

Neither can be undone, so both require `AllowDestructiveRemove = $true`. `IsDisabled = $true` is the reversible alternative and is usually what is actually wanted.

Colour is compared ignoring a leading `#` and case-insensitively, since the API returns a bare uppercase hex value and configurations are written either way.

## Examples

## Example 1: Sample Configuration using AzDoProcessWorkItemType Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoProcess ContosoAgile {
            Ensure            = 'Present'
            ProcessName       = 'Contoso Agile'
            ParentProcessName = 'Agile'
        }

        AzDoProcessWorkItemType Incident {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            Description      = 'A production incident'
            Color            = 'F6546A'
            Icon             = 'icon_flame'
            DependsOn        = '[AzDoProcess]ContosoAgile'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoProcessWorkItemType
$properties = @{
    ProcessName      = 'Contoso Agile'
    WorkItemTypeName = 'Incident'
}

Invoke-DscResource -Name 'AzDoProcessWorkItemType' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {}

resources:
- name: Incident Work Item Type
  type: AzureDevOpsDscNative/AzDoProcessWorkItemType
  dependsOn:
    - AzureDevOpsDscNative/AzDoProcess/Contoso Agile
  properties:
    ProcessName: Contoso Agile
    WorkItemTypeName: Incident
    Description: A production incident
    Color: F6546A
    Icon: icon_flame
    Ensure: Present
```

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
