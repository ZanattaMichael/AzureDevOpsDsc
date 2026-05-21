<#
    .DESCRIPTION
        This example shows how to create a variable group in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoVariableGroup 'AddAzDoVariableGroup'
        {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            Description       = 'Shared pipeline variables'
            VariableGroupType = 'Vsts'
            AllowAccess       = $true
            Variables         = @{
                APP_ENV        = 'production'
                APP_LOG_LEVEL  = 'warn'
            }
        }
    }
}
