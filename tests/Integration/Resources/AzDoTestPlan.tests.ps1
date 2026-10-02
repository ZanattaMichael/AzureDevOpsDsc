# Creating a test plan requires the DSC identity to have a Test Plans license/access level in the
# organization, in addition to Basic access. Where that access level is not granted, the API
# refuses with an access/permission error; the tests that need to create a test plan are skipped
# rather than failed in that case, since the resource cannot be exercised at all.

Describe "AzDoTestPlan Integration Tests" -Tag "Integration", "TestManagement" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TESTPLAN'
        $PLANNAME    = 'DSC_TEST_PLAN'

        $parameters = @{
            Name       = 'AzDoTestPlan'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                Name        = $PLANNAME
                AreaPath    = $PROJECTNAME
                State       = 'Active'
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        $script:accessRefused = $false
    }

    Context "Testing if the test plan exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the test plan" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (test plan does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the test plan" {

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

        It "Should not throw any exceptions when creating the test plan" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the test plan" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Re-testing an unchanged test plan" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should remain in the desired state when tested repeatedly" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Ignoring an unbound property" {

        It "Should ignore Iteration when it is not bound" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $altParameters = @{
                Name       = 'AzDoTestPlan'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    Name        = $PLANNAME
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Drifting and fixing the state" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Name        = $PLANNAME
                State       = 'Inactive'
            }
        }

        It "Should report drift when the state changes" {
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

    Context "Removing the test plan" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                Name        = $PLANNAME
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the test plan" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (test plan absent is the desired state)" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
