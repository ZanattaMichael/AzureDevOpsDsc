<#
    .DESCRIPTION
        This example shows how to deny read access to a shared Analytics view for a group in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoAnalyticsViewsPermission 'AddAzDoAnalyticsViewsPermission'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $false
            Permissions = @(
                @{ Permission = 'Read'; Access = 'Deny' }
            )
        }
    }
}
