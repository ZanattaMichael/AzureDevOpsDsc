<#
    .DESCRIPTION
        This example shows how to remove a Orgnaization Group
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoOrganizationGroup 'DeleteAzDoOrganizationGroup'
        {
            Ensure               = 'Absent'
            GroupName            = 'Updated Group Name'
        }
    }
}
