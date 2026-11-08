<#
    .DESCRIPTION
        This example shows how to add groups to a membership.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
