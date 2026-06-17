Describe "AzDoAuditStream Integration Tests" -Tag "Integration", "AuditStream" {

    BeforeAll {

        # An Azure Event Hub audit stream is the simplest to test without real
        # workspace or Splunk credentials.  The connection string here is a
        # syntactically valid placeholder; the API will reject it at runtime if
        # the Event Hub does not exist — the tests are therefore marked -Skip
        # until a real Event Hub is provisioned for the test environment.
        $STREAMNAME = 'TEST_AUDITSTREAM'

        $parameters = @{
            Name       = 'AzDoAuditStream'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                StreamName     = $STREAMNAME
                ConsumerType   = 'AzureEventHub'
                ConsumerInputs = @{
                    connectionString = 'Endpoint=sb://test.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=PLACEHOLDER='
                    eventHubName     = 'auditlogs'
                }
                Enabled        = $true
            }
        }
    }

    Context "Testing if the audit stream exists" -Skip {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (stream does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the audit stream" -Skip {

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

    Context "Disabling the audit stream" -Skip {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Enabled = $false
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after disabling" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the audit stream" -Skip {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                StreamName     = $STREAMNAME
                ConsumerType   = 'AzureEventHub'
                ConsumerInputs = @{ connectionString = 'placeholder'; eventHubName = 'auditlogs' }
                Ensure         = 'Absent'
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
