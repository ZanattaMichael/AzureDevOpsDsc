Describe "AzDoPipelineEnvironment Integration Tests" -Tag "Integration", "PipelineEnvironment" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PIPELINE_ENV'

        $parameters = @{
            Name       = 'AzDoPipelineEnvironment'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName     = $PROJECTNAME
                EnvironmentName = 'TEST_ENV'
                Description     = 'Test pipeline environment'
            }
        }

        New-Project $PROJECTNAME
    }

    Context "Testing if the environment exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (environment does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the environment" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the environment description" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Description = 'Updated test pipeline environment'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after update" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the environment" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName     = $PROJECTNAME
                EnvironmentName = 'TEST_ENV'
                Ensure          = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
