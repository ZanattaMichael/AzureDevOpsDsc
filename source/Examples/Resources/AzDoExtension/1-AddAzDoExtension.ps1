<#
    .DESCRIPTION
        This example shows how to install an extension in an Azure DevOps organization.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoExtension 'AddAzDoExtension'
        {
            Ensure      = 'Present'
            PublisherId = 'ms'
            ExtensionId = 'vss-services-github'
        }
    }
}
