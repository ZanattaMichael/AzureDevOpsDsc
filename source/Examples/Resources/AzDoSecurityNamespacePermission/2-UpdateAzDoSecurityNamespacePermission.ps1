<#
    .DESCRIPTION
        This example shows how to update permissions within a security namespace in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoSecurityNamespacePermission 'UpdateAzDoSecurityNamespacePermission'
        {
            Ensure            = 'Present'
            SecurityNamespace = 'Build'
            Token             = 'repoV2/00000000-0000-0000-0000-000000000001'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $false
            Permissions       = @(
                @{ Permission = 'ViewBuilds'; Access = 'Allow' }
                @{ Permission = 'QueueBuilds'; Access = 'Allow' }
                @{ Permission = 'DeleteBuilds'; Access = 'Deny' }
            )
        }
    }
}
