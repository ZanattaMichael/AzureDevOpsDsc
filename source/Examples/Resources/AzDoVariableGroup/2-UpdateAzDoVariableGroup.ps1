<#
    .DESCRIPTION
        This example shows how to update a variable group in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

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
