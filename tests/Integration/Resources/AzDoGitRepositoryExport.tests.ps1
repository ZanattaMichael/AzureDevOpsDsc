using module AzureDevOpsDscNative

<#
    Integration test for the DSC v3 export path on AzDoGitRepository: [AzDoGitRepository]::Export().

    Creates its own uniquely named project and repository, calls the class's static
    Export() method against the live organization, finds that repository among the
    exported results, feeds the exported properties into Invoke-DscResource -Method
    Test, and asserts the result is already in the desired state. Never reads or
    modifies any project or repository it did not create itself. Deleting the owned
    project at the end also removes the repository, so no separate repository cleanup
    is needed.
#>

Describe "AzDoGitRepository Export Integration Tests" -Tag "Integration", "GitRepository", "Export" {

    BeforeAll {

        $PROJECTNAME    = "TESTPROJECT_REPOEXPORT_$(Get-Random -Maximum 999999)"
        $REPOSITORYNAME = 'TESTREPOSITORY_EXPORT'

        $parameters = @{
            Name       = 'AzDoGitRepository'
            ModuleName = 'AzureDevOpsDscNative'
        }

        New-TestProject -ProjectName $PROJECTNAME

        # Create the repository through the resource rather than straight through REST. Get reads
        # the LiveRepositories cache, which is built when the run authenticates; New adds the
        # repository to it, whereas a repository created behind its back stays invisible to Get
        # (and to Test) for the rest of the run, even though Export lists it live.
        $createParameters = $parameters.Clone()
        $createParameters.Method   = 'Set'
        $createParameters.property = @{
            ProjectName    = $PROJECTNAME
            RepositoryName = $REPOSITORYNAME
            Ensure         = 'Present'
        }
        Invoke-DscResource @createParameters
    }

    AfterAll {

        # Deleting the project this test created also removes the repository created
        # inside it, so a single Absent Set on the project is sufficient cleanup.
        $projectParameters = @{
            Name       = 'AzDoProject'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName = $PROJECTNAME
                Ensure      = 'Absent'
            }
        }
        Invoke-DscResource @projectParameters
    }

    Context "Exporting git repositories from the live organization" {

        BeforeAll {
            $script:exported = @([AzDoGitRepository]::Export())
            $script:own      = $script:exported | Where-Object {
                $_.ProjectName -eq $PROJECTNAME -and $_.RepositoryName -eq $REPOSITORYNAME
            }
        }

        It "Should not throw" {
            { @([AzDoGitRepository]::Export()) } | Should -Not -Throw
        }

        It "Should include the repository this test created" {
            $script:own | Should -Not -BeNullOrEmpty
        }

        It "Should export Ensure = Present" {
            $script:own.Ensure | Should -Be 'Present'
        }

        It "Should be in the desired state when the exported properties are fed back through Test" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName    = $script:own.ProjectName
                RepositoryName = $script:own.RepositoryName
            }

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
