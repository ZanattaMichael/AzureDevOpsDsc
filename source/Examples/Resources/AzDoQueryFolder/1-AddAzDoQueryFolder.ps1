<#
    .DESCRIPTION
        This example shows how to create a folder in the shared work item query tree of an
        Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoQueryFolder 'AddAzDoQueryFolder'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform'
        }
    }
}
