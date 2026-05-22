<#
    .DESCRIPTION
        This example shows how to remove a service connection from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoServiceConnection 'RemoveAzDoServiceConnection'
        {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureServiceConnection'
            ConnectionType = 'AzureRM'
        }
    }
}
