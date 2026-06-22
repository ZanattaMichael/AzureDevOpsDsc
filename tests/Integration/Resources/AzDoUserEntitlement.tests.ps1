# Adding a user entitlement requires a REAL invitable AAD identity and consumes a license, so there is
# no safe throwaway user to create/destroy in the shared test organization. The principal name is also
# PII, and this is a public repository — so it is NEVER hard-coded here. It is supplied at run time via
# the AZDODSC_TEST_USER_UPN environment variable (set it as a SECRET / masked pipeline variable in CI so
# the value is redacted from logs). When it is not set the tests are skipped.
#
#   # locally:
#   $env:AZDODSC_TEST_USER_UPN = '<disposable-test-account-upn>'
#
# The resource code and these tests are written so the principal name is never written to output (no
# Write-Host/verbose/exception includes it), so it cannot leak into the test transcript or results XML.

$TEST_USER = $env:AZDODSC_TEST_USER_UPN
$skipUserEntitlement = [string]::IsNullOrWhiteSpace($TEST_USER)

Describe "AzDoUserEntitlement Integration Tests" -Tag "Integration", "UserEntitlement" {

    BeforeAll {
        $TEST_USER = $env:AZDODSC_TEST_USER_UPN

        $parameters = @{
            Name       = 'AzDoUserEntitlement'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                UserPrincipalName  = $TEST_USER
                AccountLicenseType = 'stakeholder'
            }
        }
    }

    Context "Adding the user" {

        It "Should not throw when adding the user" -Skip:$skipUserEntitlement {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after adding" -Skip:$skipUserEntitlement {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing the access level" {

        It "Should not throw when changing the license" -Skip:$skipUserEntitlement {
            $parameters.Method = 'Set'
            $parameters.property.AccountLicenseType = 'express'
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after the change" -Skip:$skipUserEntitlement {
            Start-Sleep -Seconds 5
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the user" {

        It "Should not throw when removing the user" -Skip:$skipUserEntitlement {
            $parameters.Method = 'Set'
            $parameters.property = @{
                UserPrincipalName  = $TEST_USER
                AccountLicenseType = 'stakeholder'
                Ensure             = 'Absent'
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after removal" -Skip:$skipUserEntitlement {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
