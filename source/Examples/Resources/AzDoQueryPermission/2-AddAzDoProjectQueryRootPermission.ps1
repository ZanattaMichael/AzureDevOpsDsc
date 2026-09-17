<#
    .DESCRIPTION
        This example shows how to set the baseline permissions for every query in a project by
        omitting QueryPath, which targets the project's query root.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoQueryPermission 'AddProjectQueryRootPermission'
        {
            ProjectName = 'MyProject'
            isInherited = $true
            Permissions = @(
                @{
                    Identity    = '[MyProject]\Contributors'
                    Permission  = @{ Read = 'Allow' }
                }
            )
        }
    }
}
