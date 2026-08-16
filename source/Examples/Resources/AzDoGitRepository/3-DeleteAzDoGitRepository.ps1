<#
    .DESCRIPTION
        This example shows how to remove a Git Repository.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

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
