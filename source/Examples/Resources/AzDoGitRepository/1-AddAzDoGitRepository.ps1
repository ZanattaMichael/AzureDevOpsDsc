<#
    .DESCRIPTION
        This example shows how to add the Git Repository, including seeding it from an
        existing source at creation time (issue #73).

        'SourceRepository' is only ever used when the repository is created - it has no
        effect on an existing repository, and is never re-applied by Set().

        'SourceType' picks how 'SourceRepository' is used:
          - 'Import' clones the content of an external Git URL into the new repository via
            the Import Requests API. Inferred automatically when 'SourceRepository' looks
            like a URL (e.g. starts with 'https://' or is an SSH remote like
            'git@host:owner/repo.git').
          - 'Fork' copies an existing repository in this organization (either
            'RepositoryName' in the same project, or 'ProjectName/RepositoryName' to fork
            from a different project). Inferred automatically otherwise.

        'ImportServiceConnectionName' supplies the generic Git service connection used to
        authenticate an 'Import' against a private source repository. Omit it for a public
        source.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        # A plain, empty repository.
        AzDoGitRepository 'AddGitRepository'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            RepositoryName       = 'Test Repository'
        }

        # Import the content of a public external Git repository.
        AzDoGitRepository 'ImportGitRepository'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            RepositoryName       = 'Imported Repository'
            SourceRepository     = 'https://github.com/octocat/Hello-World.git'
        }

        # Import the content of a private external Git repository, authenticating via a
        # generic Git service connection already configured in the project.
        AzDoGitRepository 'ImportPrivateGitRepository'
        {
            Ensure                      = 'Present'
            ProjectName                 = 'Test Project'
            RepositoryName              = 'Imported Private Repository'
            SourceRepository            = 'https://github.com/my-org/my-private-repo.git'
            ImportServiceConnectionName = 'GitHub-Import'
        }

        # Fork another repository already in this organization.
        AzDoGitRepository 'ForkGitRepository'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            RepositoryName       = 'Forked Repository'
            SourceRepository     = 'Other Project/Source Repository'
            SourceType           = 'Fork'
        }
    }
}
