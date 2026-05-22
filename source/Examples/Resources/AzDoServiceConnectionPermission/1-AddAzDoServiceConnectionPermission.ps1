<#
    .DESCRIPTION
        This example shows how to grant permissions on a service connection in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoServiceConnectionPermission 'AddAzDoServiceConnectionPermission'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureServiceConnection'
            GroupName      = '[MyProject]\Contributors'
            isInherited    = $true
            Permissions    = @(
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}
