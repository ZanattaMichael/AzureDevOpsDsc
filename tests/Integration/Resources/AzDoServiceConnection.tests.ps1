Describe "AzDoServiceConnection Integration Tests (Generic UsernamePassword connection)" {

    BeforeAll {

        $PROJECTNAME = 'TEST_SERVICECONNECTION'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        # Generic (no-secrets) service connection using a placeholder endpoint type.
        # Uses 'Generic' connection type which requires username+password but is broadly
        # available without external service dependency.
        $parameters = @{
            Name       = 'AzDoServiceConnection'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName    = $PROJECTNAME
                ConnectionName = 'TEST_SC'
                ConnectionType = 'Generic'
                Description    = 'Test service connection'
                Authorization  = @{
                    scheme   = 'UsernamePassword'
                    username = 'testuser'
                    password = 'testpassword'
                }
                Data           = @{
                    url = 'https://test.example.com'
                }
            }
        }

        New-Project $PROJECTNAME
    }

    Context "Testing if the Generic service connection exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the Generic service connection" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (Generic service connection does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the Generic service connection" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the Generic service connection" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the Generic service connection" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the Generic service connection description" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Description = 'Updated test service connection'
        }

        It "Should not throw any exceptions when updating the Generic service connection" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after updating the Generic service connection" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the Generic service connection" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName    = $PROJECTNAME
                ConnectionName = 'TEST_SC'
                ConnectionType = 'Generic'
                Ensure         = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the Generic service connection" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Generic service connection absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
