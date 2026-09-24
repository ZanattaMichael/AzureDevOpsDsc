using module AzureDevOpsDscNative

<#
    Integration test for the DSC v3 export path on AzDoProject: [AzDoProject]::Export().

    Creates its own uniquely named project, calls the class's static Export() method
    against the live organization, finds that project among the exported results, feeds
    the exported properties straight into Invoke-DscResource -Method Test, and asserts
    the result is already in the desired state - proving Export() -> Test() is a true
    round trip. Never reads or modifies any project it did not create itself.
#>

Describe "AzDoProject Export Integration Tests" -Tag "Integration", "Project", "Export" {

    BeforeAll {

        $PROJECTNAME = "TESTPROJECT_EXPORT_$(Get-Random -Maximum 999999)"

        $parameters = @{
            Name       = 'AzDoProject'
            ModuleName = 'AzureDevOpsDscNative'
        }

        # Create the project this test owns, with a description and Public visibility so
        # the export mapping (Ensure/ProjectDescription/Visibility) is exercised, not just
        # defaults.
        $parameters.Method   = 'Set'
        $parameters.property = @{
            ProjectName        = $PROJECTNAME
            ProjectDescription = 'Created by the AzDoProject export integration test.'
            Visibility         = 'Public'
        }
        Invoke-DscResource @parameters
    }

    AfterAll {

        # Clean up the project this test created, regardless of what the assertions did.
        $parameters.Method   = 'Set'
        $parameters.property = @{
            ProjectName = $PROJECTNAME
            Ensure      = 'Absent'
        }
        Invoke-DscResource @parameters
    }

    Context "Exporting projects from the live organization" {

        BeforeAll {
            $script:exported = @([AzDoProject]::Export())
            $script:own      = $script:exported | Where-Object { $_.ProjectName -eq $PROJECTNAME }
        }

        It "Should not throw" {
            { @([AzDoProject]::Export()) } | Should -Not -Throw
        }

        It "Should include the project this test created" {
            $script:own | Should -Not -BeNullOrEmpty
        }

        It "Should export the description and visibility this test set" {
            $script:own.ProjectDescription | Should -Be 'Created by the AzDoProject export integration test.'
            $script:own.Visibility | Should -Be 'Public'
            $script:own.Ensure | Should -Be 'Present'
        }

        It "Should be in the desired state when the exported properties are fed back through Test" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName        = $script:own.ProjectName
                ProjectDescription = $script:own.ProjectDescription
                Visibility         = $script:own.Visibility.ToString()
            }

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
