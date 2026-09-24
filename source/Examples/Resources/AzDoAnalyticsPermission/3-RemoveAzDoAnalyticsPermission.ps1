<#
    .DESCRIPTION
        This example shows how to remove explicit analytics permissions from a group, reverting
        it to inherited permissions.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoAnalyticsPermission 'RemoveAzDoAnalyticsPermission'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
        }
    }
}
