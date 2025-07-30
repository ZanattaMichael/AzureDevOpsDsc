<#
    .DESCRIPTION
        This example shows how to add Project Area Paths.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaNodes 'AddAzDoAreaNodes'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            AreaPaths            = @(
                '\Test Area\Sub Area'
                '\Test Area\'
            )
        }
    }
}
