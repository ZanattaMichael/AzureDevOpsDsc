Describe "AzDoExtension Integration Tests (ms-devlabs.team-calendar)" -Tag "Integration", "Extension" {

    BeforeAll {

        # Use a well-known, free Marketplace extension that is safe to install/uninstall
        # in a test organisation: the Microsoft DevLabs "Team Calendar" extension.
        $PUBLISHERID  = 'ms-devlabs'
        $EXTENSIONID  = 'team-calendar'

        $parameters = @{
            Name       = 'AzDoExtension'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                PublisherId = $PUBLISHERID
                ExtensionId = $EXTENSIONID
            }
        }
    }

    Context "Testing if the Team Calendar extension is installed" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the Team Calendar extension" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Ensuring the Team Calendar extension is installed (Present)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Ensure = 'Present'
        }

        It "Should not throw any exceptions when installing the Team Calendar extension" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after installing the Team Calendar extension" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Ensuring the Team Calendar extension is uninstalled (Absent)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions when uninstalling the Team Calendar extension" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after uninstalling the Team Calendar extension" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
