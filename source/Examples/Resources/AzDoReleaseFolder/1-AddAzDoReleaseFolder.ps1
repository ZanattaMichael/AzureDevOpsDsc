<#
    .DESCRIPTION
        This example creates a classic Release Management folder.

        Release folder paths are backslash-delimited, the same convention used by pipeline
        folders, but the folder lives on the vsrm.dev.azure.com host.
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
            Description = 'Platform team releases'
        }
    }
}
