Describe "AzDoProcess Integration Tests" -Tag "Integration", "Process" {

    BeforeAll {

        # Inherited processes cannot be created twice with the same name, and a name may be briefly
        # reserved after deletion — use a unique name per run.
        $PROCESSNAME = "ITProcess$(Get-Random -Maximum 99999)"

        $parameters = @{
            Name       = 'AzDoProcess'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProcessName       = $PROCESSNAME
                ParentProcessName = 'Agile'
                Description       = 'Inherited process for integration testing'
            }
        }
    }

    Context "Testing if the process exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (process not yet created)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the process" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the description" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Description = 'Updated inherited process description'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after the description update" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the process" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after removal" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
