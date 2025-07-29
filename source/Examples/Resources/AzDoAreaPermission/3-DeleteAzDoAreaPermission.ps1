<#
    .DESCRIPTION
        This example shows how to remove Area Path permissions.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaPermission 'DeleteAreaPathPermission'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            AreaPath             = '\Test Area\Sub Area'
            isInherited          = $false
            # Note: Permissions can be empty to remove all permissions
            # Ensure = 'Absent' is not required.
            # Please note that by setting isInherited to $true, the permissions will be inherited from the parent area path.
            # If you want to remove all permissions, you can set isInherited to $false and provide an empty Permissions array.
            Permissions          = @()
        }
    }
}
