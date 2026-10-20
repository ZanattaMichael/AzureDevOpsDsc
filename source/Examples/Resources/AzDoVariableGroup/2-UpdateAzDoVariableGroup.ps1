<#
    .DESCRIPTION
        This example shows how to update a variable group in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoVariableGroup 'UpdateAzDoVariableGroup'
        {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            Description       = 'Shared pipeline variables - updated'
            VariableGroupType = 'Vsts'
            AllowAccess       = $true
            Variables         = @{
                APP_ENV        = 'production'
                APP_LOG_LEVEL  = 'info'
                APP_VERSION    = '2.0.0'
            }
        }
    }
}
