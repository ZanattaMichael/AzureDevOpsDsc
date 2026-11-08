<#
    .DESCRIPTION
        This example shows how to update the Git Repository.

        Set() only ever applies 'IsDisabled'. 'SourceRepository', 'SourceType' and
        'ImportServiceConnectionName' seed a repository once, at creation time (see
        1-AddAzDoGitRepository.ps1) - they are never re-applied and Test() never reports
        drift on them for a repository that already exists.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoGitRepository 'DisableGitRepository'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            RepositoryName       = 'Test Repository'
            IsDisabled           = $true
        }
    }
}
