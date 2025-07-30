<#
    .DESCRIPTION
        This example shows how to update Project Area Paths.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaNodes 'UpdateAzDoAreaNodes'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            AreaPaths            = @(
                '\Test Area\Sub Area'
                '\Test Area\'
                '\New Area\Sub Area'
            )
        }
    }
}
