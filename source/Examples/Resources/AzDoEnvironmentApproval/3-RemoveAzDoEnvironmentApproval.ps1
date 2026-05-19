<#
    .DESCRIPTION
        This example shows how to remove approval gates from a pipeline environment in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoEnvironmentApproval 'RemoveAzDoEnvironmentApproval'
        {
            Ensure          = 'Absent'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            Approvers       = @()
        }
    }
}
