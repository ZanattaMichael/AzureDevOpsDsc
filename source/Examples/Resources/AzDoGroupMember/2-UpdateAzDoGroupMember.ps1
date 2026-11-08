<#
    .DESCRIPTION
        TThis example shows how to update the group membership.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoGroupMember 'UpdateAzDoGroupMember'
        {
            Ensure               = 'Present'
            GroupName            = '[ProjectName|OrganizationName]\GroupName'
            GroupMembers         = @(
                '[Project]\New Group Name'
                '[OrganizationName]\Project Collection Administrators'
            )
        }
    }
}
