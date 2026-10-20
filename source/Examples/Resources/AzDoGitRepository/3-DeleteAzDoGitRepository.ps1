<#
    .DESCRIPTION
        This example shows how to remove a Git Repository.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoGitRepository 'RemoveGitRepository'
        {
            Ensure               = 'Absent'
            ProjectName          = 'Test Project'
            RepositoryName       = 'Test Repository'
        }
    }
}
