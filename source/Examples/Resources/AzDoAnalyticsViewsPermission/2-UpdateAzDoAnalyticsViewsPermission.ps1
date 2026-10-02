<#
    .DESCRIPTION
        This example shows how to grant write access on a shared Analytics view for a group in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoAnalyticsViewsPermission 'UpdateAzDoAnalyticsViewsPermission'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $false
            Permissions = @(
                @{ Permission = 'Write'; Access = 'Allow' }
            )
        }
    }
}
