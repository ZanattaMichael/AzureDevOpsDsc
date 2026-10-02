Describe "AzDoGitRepository Integration Tests" -Tag "Integration", "GitRepository" {

    BeforeAll {

        # Perform setup tasks here
        $PROJECTNAME = 'TESTPROJECT_GITREPOSITORY'

        # Define common parameters
        $parameters = @{
            Name = 'AzDoGitRepository'
            ModuleName = 'AzureDevOpsDscNative'
        }

        # Fetches a repository's own metadata (id, defaultBranch, etc) directly from the REST
        # API, bypassing the module's cache so the assertion reflects what Azure DevOps actually
        # has, not what the resource believes it wrote.
        function Get-TestGitRepository {
            param([string]$ProjectName, [string]$RepositoryName)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            try {
                return Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    'https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}?api-version=7.1-preview.1' -f
                        $org, $ProjectName, $RepositoryName)
            } catch {
                throw "[Get-TestGitRepository] Failed to get repository '$RepositoryName' in project '$ProjectName'. Error: $_"
            }
        }

        # An import that silently failed still leaves an empty repository behind - checking the
        # repository "exists" is not enough to prove the import actually ran. Commits are the
        # ground truth: an empty repo has none, an imported one has whatever the source had.
        function Get-TestGitRepositoryCommits {
            param([string]$ProjectName, [string]$RepositoryId)

            $org = Resolve-TestOrg
            $hdr = Resolve-TestAuthHeader

            try {
                return (Invoke-RestMethod -Headers $hdr -Method Get -Uri (
                    'https://dev.azure.com/{0}/{1}/_apis/git/repositories/{2}/commits?api-version=7.1' -f
                        $org, $ProjectName, $RepositoryId)).value
            } catch {
                # A repository with no commits (e.g. one that was never successfully imported)
                # answers with a 404/'does not have any commits' rather than an empty array.
                if ($_ -match '404' -or $_ -match 'does not have any commits' -or $_ -match 'was not found') {
                    return @()
                }

                throw "[Get-TestGitRepositoryCommits] Failed to get commits for repository '$RepositoryId' in project '$ProjectName'. Error: $_"
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

    }

    # This context is used to test if a git repository exists.
    Context "Testing if a Git Repository Exists" {

        BeforeAll {
            # Set up the parameters for the DSC resource invocation.
            # 'Method' is set to 'Test', which means we are testing the presence of a resource.
            $parameters.Method = 'Test'

            # Define properties for the DSC resource.
            # In this case, we specify a project name 'TESTPROJECT'.
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                RepositoryName = 'TESTREPOSITORY'
            }

        }

        It "Should not throw any exceptions" {
            # Test that invoking the DSC resource with the specified parameters does not throw any exceptions.
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False" {
            # Invoke the DSC resource with the specified parameters and store the result.
            $result = Invoke-DscResource @parameters

            # Verify that the 'Ensure' property in the result is 'Absent',
            # indicating that the git repository 'TESTREPOSITORY' does not exist.
            $result.InDesiredState | Should -BeFalse
        }

    }

    # This context is used to test the creation of a new git repository.
    Context "Creating a new Git Repository Permissions" {

        BeforeAll {
            # Set up the parameters for the DSC resource invocation.
            # 'Method' is set to 'Set', which means we are creating a new resource.
            $parameters.Method = 'Set'

            # Define properties for the DSC resource.
            # In this case, we specify a project name using the variable '$PROJECTNAME'.
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                RepositoryName = 'TESTREPOSITORY'
                Ensure = 'Present'
            }
        }

        It "Should not throw any exceptions" {
            # Test that invoking the DSC resource with the specified parameters does not throw any exceptions.
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {

            # Update the 'Method' property to 'Test' to test the presence of the git repository.
            $parameters.Method = 'Test'

            # Invoke the DSC resource with the specified parameters and store the result.
            $result = Invoke-DscResource @parameters

            # Verify that the 'Ensure' property in the result is 'Present',
            # indicating that the git repository 'TESTREPOSITORY' exists.
            $result.InDesiredState | Should -BeTrue
        }

    }

    # This context is used to test the deletion of a git repository.
    Context "Deleting an Existing Git Repository" {

        BeforeAll {
            # Set up the parameters for the DSC resource invocation.
            # 'Method' is set to 'Set', which means we are deleting an existing resource.
            $parameters.Method = 'Set'

            # Define properties for the DSC resource.
            # In this case, we specify a project name using the variable '$PROJECTNAME'.
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                RepositoryName = 'TESTREPOSITORY'
                Ensure = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            # Test that invoking the DSC resource with the specified parameters does not throw any exceptions.
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True" {

            $parameters.Method = 'Test'

            # Invoke the DSC resource with the specified parameters and store the result.
            $result = Invoke-DscResource @parameters

            # Verify that the 'Ensure' property in the result is 'Absent',
            # indicating that the git repository 'TESTREPOSITORY' was deleted.
            $result.InDesiredState | Should -BeTrue
        }

    }

    # This context is used to test importing a repository from a public source at creation time
    # (issue #73). A silently-empty repository would still pass a naive existence check, so the
    # assertion below verifies commits actually landed, not just that the resource reports success.
    Context "Importing a Git Repository from a public source" {

        BeforeAll {
            $IMPORTREPOSITORYNAME = 'TESTREPOSITORY_IMPORT'

            $parameters.Method = 'Set'

            $parameters.property = @{
                ProjectName      = $PROJECTNAME
                RepositoryName   = $IMPORTREPOSITORYNAME
                SourceRepository = 'https://github.com/octocat/Hello-World.git'
                Ensure           = 'Present'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (import completed and the repository is in the desired state)" {
            $parameters.Method = 'Test'

            $result = Invoke-DscResource @parameters

            $result.InDesiredState | Should -BeTrue
        }

        It "Should not report drift on a second Test - SourceRepository is create-time only" {
            $parameters.Method = 'Test'

            $result = Invoke-DscResource @parameters

            $result.InDesiredState | Should -BeTrue
        }

        It "Should have imported commits from the source repository rather than creating an empty repo" {
            $repo = Get-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName $IMPORTREPOSITORYNAME

            $repo.id | Should -Not -BeNullOrEmpty
            $repo.defaultBranch | Should -Not -BeNullOrEmpty

            $commits = @(Get-TestGitRepositoryCommits -ProjectName $PROJECTNAME -RepositoryId $repo.id)
            $commits.Count | Should -BeGreaterThan 0
        }
    }

}
