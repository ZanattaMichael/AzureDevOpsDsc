# Adding a user entitlement requires a REAL invitable AAD identity and consumes a license, so there is
# no safe throwaway user to create/destroy in the shared test organization. These tests therefore only
# run when the AZDODSC_TEST_USER_UPN environment variable is set to a principal name (email/UPN) that is
# safe to add to and remove from the organization. When it is not set the tests are skipped.
#
#   $env:AZDODSC_TEST_USER_UPN = 'testuser@yourtenant.onmicrosoft.com'

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
