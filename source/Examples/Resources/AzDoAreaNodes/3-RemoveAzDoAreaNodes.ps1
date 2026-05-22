<#
    .DESCRIPTION
        This example shows how to remove area nodes from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaNodes 'RemoveAzDoAreaNodes'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
        }
    }
}
