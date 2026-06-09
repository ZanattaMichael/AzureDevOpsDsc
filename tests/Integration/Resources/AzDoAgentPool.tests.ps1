Describe "AzDoAgentPool Integration Tests" {

    BeforeAll {

        $POOLNAME = 'TEST_AGENTPOOL'

        $parameters = @{
            Name       = 'AzDoAgentPool'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                PoolName      = $POOLNAME
                PoolType      = 'automation'
                AutoProvision = $false
                AutoUpdate    = $true
                IsHosted      = $false
            }
        }
    }

    Context "Testing if the agent pool exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (agent pool does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the agent pool" {

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

    Context "Updating the agent pool" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.AutoUpdate = $false
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

    Context "Removing the agent pool" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                PoolName = $POOLNAME
                Ensure   = 'Absent'
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
