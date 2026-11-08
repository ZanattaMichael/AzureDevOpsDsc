<#
    .DESCRIPTION
        This example creates a pipeline folder.

        Pipeline folder paths are backslash-delimited, unlike work item query paths.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
            Description = 'Platform team pipelines'
        }
    }
}
