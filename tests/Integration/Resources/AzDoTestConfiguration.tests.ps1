# Creating a test configuration requires the DSC identity to have a Test Plans license/access
# level in the organization, in addition to Basic access. Where that access level is not granted,
# the API refuses with an access/permission error; the tests that need to create a test
# configuration are skipped rather than failed in that case, since the resource cannot be
# exercised at all.

Describe "AzDoTestConfiguration Integration Tests" -Tag "Integration", "TestManagement" {

    BeforeAll {

        $PROJECTNAME    = 'TEST_TESTCONFIGURATION'
        $VARIABLENAME   = 'DSC_TEST_BROWSER'
        $CONFIGNAME     = 'DSC_TEST_WINDOWS_EDGE'

        $variableParameters = @{
            Name       = 'AzDoTestVariable'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName = $PROJECTNAME
                Name        = $VARIABLENAME
                Values      = @('Edge', 'Chrome')
            }
        }

        $parameters = @{
            Name       = 'AzDoTestConfiguration'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                Name        = $CONFIGNAME
                Values      = @("$VARIABLENAME=Edge")
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        $script:accessRefused = $false

        try
        {
            Invoke-DscResource @variableParameters
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

    Context "Testing if the test configuration exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the test configuration" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (test configuration does not exist yet)" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the test configuration" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the test configuration" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the test configuration" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Re-testing an unchanged test configuration" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should remain in the desired state when tested repeatedly" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Ignoring an unbound property" {

        It "Should ignore IsDefault when it is not bound" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $altParameters = @{
                Name       = 'AzDoTestConfiguration'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    Name        = $CONFIGNAME
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Drifting and fixing the description" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Name        = $CONFIGNAME
                Values      = @("$VARIABLENAME=Edge")
                Description = 'Windows + Edge configuration'
            }
        }

        It "Should report drift when the description changes" {
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

    Context "Removing the test configuration" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Name        = $CONFIGNAME
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the test configuration" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (test configuration absent is the desired state)" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
