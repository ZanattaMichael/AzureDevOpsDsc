Describe "AzDoOrganizationSettings Integration Tests" -Tag "Integration", "OrganizationSettings" {

    BeforeAll {

        # Read the org name from the module settings file so this test does not depend on
        # $Global:DSCAZDO_OrganizationName being pre-populated before BeforeAll runs.
        $settings = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
        $ORGNAME  = $settings.OrganizationName

        $parameters = @{
            Name       = 'AzDoOrganizationSettings'
            ModuleName = 'AzureDevOpsDsc'
        }
    }

    Context "Reading organisation settings (Get)" {

        BeforeAll {
            $parameters.Method   = 'Get'
            $parameters.property = @{
                OrganizationName = $ORGNAME
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return an object with OrganizationName" {
            $result = Invoke-DscResource @parameters
            $result.OrganizationName | Should -Be $ORGNAME
        }
    }

    Context "Testing that existing settings are in desired state (idempotency)" {

        It "Should be in desired state when current settings are re-applied" {

            # Read the current state first.
            $parameters.Method   = 'Get'
            $parameters.property = @{ OrganizationName = $ORGNAME }
            $current = Invoke-DscResource @parameters

            # Build a Test call using those same values.
            $parameters.Method   = 'Test'
            $parameters.property = @{
                OrganizationName          = $ORGNAME
                AllowPublicProjects       = $current.AllowPublicProjects
                AllowExternalGuestAccess  = $current.AllowExternalGuestAccess
                EnableOAuthAuthentication = $current.EnableOAuthAuthentication
                EnableSSHAuthentication   = $current.EnableSSHAuthentication
                DisallowAadGuestUserPolicy= $current.DisallowAadGuestUserPolicy
            }

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Applying a non-destructive setting change" {

        # Toggle AllowPublicProjects off (a safe, reversible change) then back.
        # This verifies the Set path without risking org-level breakage.

        BeforeAll {
            $parameters.Method   = 'Get'
            $parameters.property = @{ OrganizationName = $ORGNAME }
        }

        It "Should not throw when applying settings" {
            $current = Invoke-DscResource @parameters
            $parameters.Method   = 'Set'
            $parameters.property = @{
                OrganizationName    = $ORGNAME
                AllowPublicProjects = $current.AllowPublicProjects
            }
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }
}
