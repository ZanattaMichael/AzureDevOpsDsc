<#
    .DESCRIPTION
        This example shows how to update permissions on a service connection in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoServiceConnectionPermission 'UpdateAzDoServiceConnectionPermission'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureServiceConnection'
            GroupName      = '[MyProject]\Contributors'
            isInherited    = $false
            Permissions    = @(
                @{ Permission = 'Use'; Access = 'Allow' }
                @{ Permission = 'Administer'; Access = 'Deny' }
            )
        }
    }
}
