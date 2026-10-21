<#
    .DESCRIPTION
        This example grants a team permissions on a release folder. Release definitions inside
        the folder inherit from it, which is how release-folder permissions are normally
        administered.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
