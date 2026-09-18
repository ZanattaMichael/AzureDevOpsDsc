Describe "AzDoServicePrincipalEntitlement Integration Tests" -Tag "Integration", "Entitlement" {

    BeforeAll {

        # Adding a service principal to the organization needs a real Entra object id and consumes
        # a license, so this test covers the read path with an id that cannot exist. The endpoint
        # is also a preview API, and the resource is expected to report "absent" rather than fail
        # when an organization does not expose it - which is what this asserts.
        $parameters = @{
            Name       = 'AzDoServicePrincipalEntitlement'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Get'
            property   = @{
                OriginId = '00000000-0000-0000-0000-00000000dead'
            }
        }
    }

    Context "Reading a service principal that is not in the organization" {

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should report the entitlement as absent" {
            $result = Invoke-DscResource @parameters
            $result.Ensure | Should -Be 'Absent'
        }
    }

    Context "Testing a service principal that is not in the organization" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                OriginId           = '00000000-0000-0000-0000-00000000dead'
                AccountLicenseType = 'express'
                Ensure             = 'Absent'
            }
        }

        It "Should report the desired state as met when Absent is desired" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
