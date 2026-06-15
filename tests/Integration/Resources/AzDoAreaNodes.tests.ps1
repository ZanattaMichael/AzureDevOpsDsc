Describe "AzDoAreaNodes Integration Tests" -Tag "Integration", "AreaNodes" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PROJECT_AREA_NODES'

        $parameters = @{
            Name       = 'AzDoAreaNodes'
            ModuleName = 'AzureDevOpsDsc'
        }

        New-Project $PROJECTNAME
    }

    Context "Initial state - no custom area nodes" {

        It "Should be in desired state with empty AreaPaths" {

            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @()
            }

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Adding a single area node" {

        It "Should not throw when setting an area path" {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @('Area1')
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after adding area path" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @('Area1')
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Adding multiple area nodes" {

        It "Should not throw when setting multiple area paths" {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @('Area1', 'Area2', 'Area3')
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state with multiple area paths" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @('Area1', 'Area2', 'Area3')
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing an area node" {

        It "Should not throw when reducing area paths" {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @('Area1', 'Area2')
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after removing area path" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @('Area1', 'Area2')
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing all custom area nodes" {

        It "Should not throw when clearing area paths" {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @()
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state with empty area paths" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                AreaPaths   = @()
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
