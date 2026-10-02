<#
    .DESCRIPTION
        This example grants a team permissions on a specific classic release definition,
        resolved by name (and, when given, by folder).
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoReleaseDefinitionPermission 'PlatformReleaseDefinitionPermissions'
        {
            ProjectName    = 'MyProject'
            DefinitionName = 'Platform Release'
            FolderPath     = '\Platform'
            isInherited    = $true
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Platform Team'
                    Permission = @{
                        ViewReleaseDefinition  = 'Allow'
                        ManageReleaseApprovers = 'Allow'
                    }
                }
            )
        }
    }
}
