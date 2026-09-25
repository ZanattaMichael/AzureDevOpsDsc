<#
    .DESCRIPTION
        This example grants a team permissions on a release folder. Release definitions inside
        the folder inherit from it, which is how release-folder permissions are normally
        administered.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoReleaseFolder 'AddPlatformReleaseFolder'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = '\Platform'
        }

        AzDoReleaseFolderPermission 'PlatformReleaseFolderPermissions'
        {
            ProjectName = 'MyProject'
            FolderPath  = '\Platform'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Platform Team'
                    Permission = @{
                        ViewReleaseDefinition  = 'Allow'
                        ManageReleaseApprovers = 'Allow'
                    }
                }
            )
            DependsOn   = '[AzDoReleaseFolder]AddPlatformReleaseFolder'
        }
    }
}
