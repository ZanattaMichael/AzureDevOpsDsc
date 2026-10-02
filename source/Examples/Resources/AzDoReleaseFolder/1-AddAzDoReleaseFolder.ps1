<#
    .DESCRIPTION
        This example creates a classic Release Management folder.

        Release folder paths are backslash-delimited, the same convention used by pipeline
        folders, but the folder lives on the vsrm.dev.azure.com host.
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
            Description = 'Platform team releases'
        }
    }
}
