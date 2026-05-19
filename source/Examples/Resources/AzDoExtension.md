# DSC AzDoExtension Resource

# Syntax

``` PowerShell
AzDoExtension [string] #ResourceName
{
    PublisherId   = [String]$PublisherId
    ExtensionId   = [String]$ExtensionId
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __PublisherId__: The publisher ID of the extension in the Visual Studio Marketplace. This is a key property.
- __ExtensionId__: The extension ID in the Visual Studio Marketplace. This is a key property.
- __Ensure__: Specifies whether the extension should be installed. Valid values are `Present` and `Absent`. Defaults to `Present`.

> **Note:** The `Version` and `DisplayName` properties are read-only (NotConfigurable) and are populated from the installed extension metadata.

# Additional Information

This resource manages the installation of extensions from the Visual Studio Marketplace in an Azure DevOps organization. Extensions can add new capabilities, integrations, and tools to Azure DevOps.

To find the `PublisherId` and `ExtensionId` for an extension, look at its URL in the Marketplace:
`https://marketplace.visualstudio.com/items?itemName={PublisherId}.{ExtensionId}`

# Examples

## Example 1: Install an extension

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoExtension 'InstallGitHubExtension' {
            Ensure      = 'Present'
            PublisherId = 'ms'
            ExtensionId = 'vss-services-github'
        }
    }
}
```

## Example 2: Uninstall an extension

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoExtension 'UninstallExtension' {
            Ensure      = 'Absent'
            PublisherId = 'ms'
            ExtensionId = 'vss-services-github'
        }
    }
}
```
