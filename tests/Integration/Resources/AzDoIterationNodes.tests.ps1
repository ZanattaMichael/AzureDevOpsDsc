Describe "AzDoIterationNodes Integration Tests" -Tag "Integration", "IterationNodes" {

    BeforeAll {

        $PROJECTNAME = 'TEST_PROJECT_ITERATION_NODES'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        $parameters = @{
            Name       = 'AzDoIterationNodes'
            ModuleName = 'AzureDevOpsDsc'
        }

        New-Project $PROJECTNAME

        # Clear any pre-existing iterations so tests start from a known state
        $null = Invoke-DscResource -Name 'AzDoIterationNodes' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
            ProjectName         = $PROJECTNAME
            IterationAttributes = @()
        }
    }

    Context "Initial state - no custom iteration nodes" {

        It "Should be in desired state with empty IterationAttributes" {

            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @()
            }

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Adding a single iteration node" {

        It "Should not throw when adding an iteration" {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @(
                    @{
                        Path      = 'Sprint1'
                        StartDate = '2025-01-01'
                        EndDate   = '2025-01-14'
                    }
                )
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after adding iteration" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @(
                    @{
                        Path      = 'Sprint1'
                        StartDate = '2025-01-01'
                        EndDate   = '2025-01-14'
                    }
                )
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Adding multiple iteration nodes" {

        It "Should not throw when adding multiple iterations" {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @(
                    @{ Path = 'Sprint1'; StartDate = '2025-01-01'; EndDate = '2025-01-14' }
                    @{ Path = 'Sprint2'; StartDate = '2025-01-15'; EndDate = '2025-01-28' }
                    @{ Path = 'Sprint3'; StartDate = '2025-01-29'; EndDate = '2025-02-11' }
                )
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state with multiple iterations" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @(
                    @{ Path = 'Sprint1'; StartDate = '2025-01-01'; EndDate = '2025-01-14' }
                    @{ Path = 'Sprint2'; StartDate = '2025-01-15'; EndDate = '2025-01-28' }
                    @{ Path = 'Sprint3'; StartDate = '2025-01-29'; EndDate = '2025-02-11' }
                )
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing an iteration node" {

        It "Should not throw when reducing iteration count" {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @(
                    @{ Path = 'Sprint1'; StartDate = '2025-01-01'; EndDate = '2025-01-14' }
                    @{ Path = 'Sprint2'; StartDate = '2025-01-15'; EndDate = '2025-01-28' }
                )
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after removing an iteration" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @(
                    @{ Path = 'Sprint1'; StartDate = '2025-01-01'; EndDate = '2025-01-14' }
                    @{ Path = 'Sprint2'; StartDate = '2025-01-15'; EndDate = '2025-01-28' }
                )
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing all custom iteration nodes" {

        It "Should not throw when clearing iterations" {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @()
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state with empty iterations" {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                IterationAttributes = @()
            }
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
