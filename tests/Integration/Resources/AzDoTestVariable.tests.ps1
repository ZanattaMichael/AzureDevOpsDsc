# Creating a test variable requires the DSC identity to have a Test Plans license/access level in
# the organization, in addition to Basic access. Where that access level is not granted, the API
# refuses with an access/permission error; the tests that need to create a test variable are
# skipped rather than failed in that case, since the resource cannot be exercised at all.

Describe "AzDoTestVariable Integration Tests" -Tag "Integration", "TestManagement" {

    BeforeAll {

        $PROJECTNAME  = 'TEST_TESTVARIABLE'
        $VARIABLENAME = 'DSC_TEST_BROWSER'

        $parameters = @{
            Name       = 'AzDoTestVariable'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                Name        = $VARIABLENAME
                Values      = @('Edge', 'Chrome')
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        $script:accessRefused = $false
    }

    Context "Testing if the test variable exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the test variable" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (test variable does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the test variable" {

        BeforeAll {
            $parameters.Method = 'Set'

            try
            {
                Invoke-DscResource @parameters
            }
            catch
            {
                if ($_.Exception.Message -match 'access|licen[cs]e|permission|TF400813|TF400898')
                {
                    $script:accessRefused = $true
                }
                else
                {
                    throw
                }
            }
        }

        It "Should not throw any exceptions when creating the test variable" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the test variable" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Re-testing an unchanged test variable" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should remain in the desired state when tested repeatedly" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Changing values not compared without being specified" {

        It "Should ignore Description when it is not bound" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $altParameters = @{
                Name       = 'AzDoTestVariable'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    Name        = $VARIABLENAME
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Drifting and fixing the allowed values" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Name        = $VARIABLENAME
                Values      = @('Edge', 'Chrome', 'Firefox')
            }
        }

        It "Should report drift when a new value is added" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }

        It "Should converge after Set" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the test variable" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Name        = $VARIABLENAME
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the test variable" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (test variable absent is the desired state)" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
