<#
    .DESCRIPTION
        This example shows how to uninstall an extension from an Azure DevOps organization.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoExtension 'RemoveAzDoExtension'
        {
            Ensure      = 'Absent'
            PublisherId = 'ms'
            ExtensionId = 'vss-services-github'
        }
    }
}
