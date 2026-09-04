# A task group is a classic-pipeline object: creating one is refused with
#
#     400 Bad Request - "The classic pipelines are disabled for this project / organization."
#
# whenever the "Disable creation of classic build and release pipelines" policy is on, which is the
# default for newer Azure DevOps organizations. Enable-TestClassicPipeline turns the policy off for
# this test project and reports whether that actually took effect; an organization-level policy
# overrides the project setting, and there the tests that need to create a task group are skipped
# rather than failed - the resource cannot be exercised against such an organization at all.

Describe "AzDoTaskGroup Integration Tests" -Tag "Integration", "TaskGroup" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TASKGROUP'

        # A minimal task group with a single PowerShell step.
        $parameters = @{
            Name       = 'AzDoTaskGroup'
            ModuleName = 'AzureDevOpsDscNative'
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

        New-TestProject -ProjectName $PROJECTNAME

        $classicPipelinesEnabled = Enable-TestClassicPipeline -ProjectName $PROJECTNAME
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
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

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
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after update" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

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
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            if (-not $classicPipelinesEnabled)
            {
                Set-ItResult -Skipped -Because 'classic pipeline creation is disabled for this organization'
            }

            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
