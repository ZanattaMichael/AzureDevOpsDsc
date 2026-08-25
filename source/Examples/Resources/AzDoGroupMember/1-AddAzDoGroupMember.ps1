<#
    .DESCRIPTION
        This example shows how to add groups to a membership.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoGroupMember 'AddAzDoGroupMember'
        {
            Ensure               = 'Present'
            GroupName            = '[ProjectName|OrganizationName]\GroupName'
            GroupMembers         = @(
                '[Project]\Readers'
                '[OrganizationName]\Project Collection Administrators'
            )
        }
    }
}
