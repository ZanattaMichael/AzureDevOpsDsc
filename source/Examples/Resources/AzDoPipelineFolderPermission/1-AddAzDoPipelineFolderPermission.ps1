<#
    .DESCRIPTION
        This example grants a team permissions on a pipeline folder. Definitions inside the
        folder inherit from it, which is how pipeline permissions are normally administered.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelineFolder 'AddPlatformFolder'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = '\Platform'
        }

        AzDoPipelineFolderPermission 'PlatformFolderPermissions'
        {
            ProjectName = 'MyProject'
            FolderPath  = '\Platform'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Platform Team'
                    Permission = @{
                        ViewBuilds  = 'Allow'
                        QueueBuilds = 'Allow'
                    }
                }
            )
            DependsOn   = '[AzDoPipelineFolder]AddPlatformFolder'
        }
    }
}
