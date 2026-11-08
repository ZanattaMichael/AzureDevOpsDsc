<#
    .DESCRIPTION
        This example shows how to configure approval gates on a pipeline environment in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
