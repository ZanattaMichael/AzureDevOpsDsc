<#
    .DESCRIPTION
        This example shows how to install a different extension in an Azure DevOps organization.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoExtension 'UpdateAzDoExtension'
        {
            Ensure      = 'Present'
            PublisherId = 'ms-devlabs'
            ExtensionId = 'workitemsearch'
        }
    }
}
