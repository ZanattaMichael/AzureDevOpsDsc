<#
    .DESCRIPTION
        This example shows how to add the Area Path permissions.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaPermission 'AddAzDoAreaPermission'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            AreaPath             = '\Test Area\Sub Area'
            isInherited          = $false
            Permissions          = @(
                @{
                    Identity   = '[Test Project]\Test Team'
                    Permission = @{
                        'WORK_ITEM_READ'  = 'Allow'
                        'GENERIC_WRITE'   = 'Allow'
                    }
                }
            )
        }
    }
}
