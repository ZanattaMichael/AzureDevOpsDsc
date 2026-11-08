<#
    .DESCRIPTION
        This example shows how to update approval gates on a pipeline environment in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoEnvironmentApproval 'UpdateAzDoEnvironmentApproval'
        {
            Ensure                = 'Present'
            ProjectName           = 'MyProject'
            EnvironmentName       = 'Production'
            Approvers             = @('approver1@example.com', 'approver2@example.com')
            RequiredApproverCount = 2
            AllowApproverToSelf   = $false
            TimeoutInMinutes      = 2880
            Instructions          = 'At least 2 approvals required for production deployments.'
        }
    }
}
