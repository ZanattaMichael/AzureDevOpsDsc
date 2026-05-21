<#
    .DESCRIPTION
        This example shows how to remove iteration nodes from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoIterationNodes 'RemoveAzDoIterationNodes'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
        }
    }
}
