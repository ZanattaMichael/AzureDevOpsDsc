<#
    .DESCRIPTION
        This example shows how to update a Orgnaization Group
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

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
