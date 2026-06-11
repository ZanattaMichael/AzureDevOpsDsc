Describe "AzDoTaskGroup Integration Tests" -Tag "Integration", "TaskGroup" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TASKGROUP'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        # A minimal task group with a single PowerShell step.
        $parameters = @{
            Name       = 'AzDoTaskGroup'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName   = $PROJECTNAME
                TaskGroupName = 'TEST_TG'
                Description   = 'Test task group'
                Category      = 'Build'
                Tasks         = @(
                    @{
                        taskId      = 'd9bafed4-0b18-4f58-968d-86655b4d2ce9'
                        version     = '2.*'
                        name        = 'CmdLineStep'
                        displayName = 'Run Command'
                        enabled     = $true
                        inputs      = @{ script = 'echo hello' }
                    }
                )
                Inputs        = @()
            }
        }

        New-Project $PROJECTNAME
    }

    Context "Testing if the task group exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (task group does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the task group" {

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

    Context "Updating the task group description" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Description = 'Updated test task group'
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

    Context "Removing the task group" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName   = $PROJECTNAME
                TaskGroupName = 'TEST_TG'
                Ensure        = 'Absent'
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
