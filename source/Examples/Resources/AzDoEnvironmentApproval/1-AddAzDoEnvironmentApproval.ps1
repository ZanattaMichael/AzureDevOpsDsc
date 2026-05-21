<#
    .DESCRIPTION
        This example shows how to configure approval gates on a pipeline environment in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoEnvironmentApproval 'AddAzDoEnvironmentApproval'
        {
            Ensure                = 'Present'
            ProjectName           = 'MyProject'
            EnvironmentName       = 'Production'
            Approvers             = @('approver@example.com')
            RequiredApproverCount = 1
            AllowApproverToSelf   = $false
            TimeoutInMinutes      = 1440
            Instructions          = 'Please review and approve the production deployment.'
        }
    }
}
