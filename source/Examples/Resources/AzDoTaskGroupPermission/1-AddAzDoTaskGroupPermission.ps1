<#
    .DESCRIPTION
        This example shows how to let a group edit one task group.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTaskGroupPermission 'AddAzDoTaskGroupPermission'
        {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            TaskGroupName = 'Deploy web app'
            isInherited   = $true
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Release Managers'
                    Permission = @{ Edit = 'Allow' }
                }
            )
        }
    }
}
