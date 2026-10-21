<#
    .DESCRIPTION
        This example shows how to update a Orgnaization Group
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoOrganizationGroup 'UpdateAzDoOrganizationGroup'
        {
            Ensure               = 'Present'
            GroupName            = 'Updated Group Name'
            GroupDescription     = 'Initial Description'
        }
    }
}
