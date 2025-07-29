<#
    .DESCRIPTION
        This example shows how to remove Iteration permissions.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoIterationPermission 'DeleteIterationPathPermission'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            IterationPath             = '\Test Iteration\Sub Iteration'
            isInherited          = $false
            # Note: Permissions can be empty to remove all permissions
            # Ensure = 'Absent' is not required.
            # Please note that by setting isInherited to $true, the permissions will be inherited from the parent Iteration path.
            # If you want to remove all permissions, you can set isInherited to $false and provide an empty Permissions array.
            Permissions          = @()
        }
    }
}
