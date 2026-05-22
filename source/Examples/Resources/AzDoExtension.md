# DSC AzDoExtension Resource

## Syntax

```PowerShell
AzDoExtension [string] #ResourceName
{
    PublisherId   = [String]$PublisherId
    ExtensionId   = [String]$ExtensionId
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **PublisherId**: The publisher ID of the extension in the Visual Studio Marketplace. This property is mandatory and serves as a key property for the resource.
- **ExtensionId**: The extension ID in the Visual Studio Marketplace. This is a key property.
- **Ensure**: Specifies whether the extension should be installed. Valid values are `Present` and `Absent`.

> **Note:** The `Version` and `DisplayName` properties are read-only and are populated from the installed extension metadata.

## Additional Information

This resource manages the installation of extensions from the Visual Studio Marketplace in an Azure DevOps organization. To find the `PublisherId` and `ExtensionId` for an extension, look at its URL in the Marketplace: `https://marketplace.visualstudio.com/items?itemName={PublisherId}.{ExtensionId}`

## Examples

## Example 1: Sample Configuration using AzDoExtension Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoExtension InstallExtension {
            Ensure      = 'Present'
            PublisherId = 'ms'
            ExtensionId = 'vss-services-github'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoExtension
$properties = @{
    PublisherId = 'ms'
    ExtensionId = 'vss-services-github'
}

Invoke-DscResource -Name 'AzDoExtension' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {}

resources:
- name: GitHub Services Extension
  type: AzureDevOpsDsc/AzDoExtension
  properties:
    PublisherId: ms
    ExtensionId: vss-services-github
    Ensure: Present

- name: Work Item Search Extension
  type: AzureDevOpsDsc/AzDoExtension
  properties:
    PublisherId: ms-devlabs
    ExtensionId: workitemsearch
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
