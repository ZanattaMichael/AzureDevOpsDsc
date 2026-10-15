<#
    .DESCRIPTION
        This example shows how to set permissions at the project level, which every task group in the project inherits.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTaskGroupPermission 'UpdateAzDoTaskGroupPermission'
        {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            isInherited   = $true
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Release Managers'
                    Permission = @{ Edit = 'Allow'; Delete = 'Deny' }
                }
            )
        }
    }
}
