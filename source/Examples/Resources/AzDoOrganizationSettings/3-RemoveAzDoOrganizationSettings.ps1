<#
    .DESCRIPTION
        This example shows how to reset organization-level settings to their defaults in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoOrganizationSettings 'RemoveAzDoOrganizationSettings'
        {
            Ensure           = 'Absent'
            OrganizationName = 'test-organization'
        }
    }
}
