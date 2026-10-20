<#
    .DESCRIPTION
        This example shows how to create a code wiki linked to a repository in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWiki 'UpdateAzDoWiki'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            WikiName       = 'MyCodeWiki'
            WikiType       = 'codeWiki'
            RepositoryName = 'MyRepository'
            MappedPath     = '/docs'
            Version        = 'main'
        }
    }
}
