<#
    .DESCRIPTION
        This example shows how to deny analytics read access for a group in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoAnalyticsPermission 'AddAzDoAnalyticsPermission'
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
