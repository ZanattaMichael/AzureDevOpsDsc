<#
    .DESCRIPTION
        This example shows how to create a nested query folder. Each level of the tree is its
        own resource: the folder resource does not create its own ancestry, so that two folders
        sharing a parent cannot race to create it.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoQueryFolder 'AddPlatformFolder'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform'
        }

        AzDoQueryFolder 'AddReleaseFolder'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform/Release'
            DependsOn   = '[AzDoQueryFolder]AddPlatformFolder'
        }
    }
}
