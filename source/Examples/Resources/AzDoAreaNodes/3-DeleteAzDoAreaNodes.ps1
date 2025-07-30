<#
    .DESCRIPTION
        This example shows how to Remove Area Paths.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaNodes 'RemoveAzDoAreaNodes'
        {
            Ensure               = 'Absent'
            ProjectName          = 'Test Project'
            AreaPaths            = @(
                '\New Area\Sub Area\To Remove'
            )
        }
    }
}
