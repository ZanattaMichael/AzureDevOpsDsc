Describe "AzDoPipeline Integration Tests (YAML pipeline)" -Tag "Integration", "Pipeline" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINE'
        $REPONAME    = 'TESTREPOSITORY_PIPELINE'
        $YAMLPATH    = 'azure-pipelines.yml'

        $parameters = @{
            Name       = 'AzDoPipeline'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName    = $PROJECTNAME
                PipelineName   = 'TEST_PIPELINE_DEF'
                RepositoryName = $REPONAME
                YamlPath       = $YAMLPATH
                FolderPath     = '\'
                DefaultBranch  = 'main'
            }
        }

        New-Project $PROJECTNAME
        New-Repository -ProjectName $PROJECTNAME -RepositoryName $REPONAME
    }

    Context "Testing if the YAML pipeline exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the YAML pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (YAML pipeline does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the YAML pipeline" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the YAML pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the YAML pipeline" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the YAML pipeline folder" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.FolderPath = '\TestFolder'
        }

        It "Should not throw any exceptions when updating the YAML pipeline folder" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after updating the YAML pipeline folder" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the YAML pipeline" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName  = $PROJECTNAME
                PipelineName = 'TEST_PIPELINE_DEF'
                RepositoryName = $REPONAME
                YamlPath     = $YAMLPATH
                Ensure       = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the YAML pipeline" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (YAML pipeline absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
