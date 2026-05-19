
<#
    .DESCRIPTION
        This example shows how to update Iteration permissions.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoIterationPermission 'UpdateAzDoIterationPermission'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            IterationPath        = '\Test Iteration\Sub Iteration'
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
