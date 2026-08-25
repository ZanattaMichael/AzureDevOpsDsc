<#
    .DESCRIPTION
        This example shows how to add a Orgnaization Group
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoOrganizationGroup 'AddAzDoOrganizationGroup'
        {
            Ensure               = 'Present'
            GroupName            = 'Initial Group Name'
            GroupDescription     = 'Initial Description'
        }
    }
}
