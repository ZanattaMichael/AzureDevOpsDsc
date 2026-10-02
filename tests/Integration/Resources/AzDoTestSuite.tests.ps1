# Creating a test suite requires the DSC identity to have a Test Plans license/access level in the
# organization, in addition to Basic access. Where that access level is not granted, the API
# refuses with an access/permission error; the tests that need to create a test plan or suite are
# skipped rather than failed in that case, since the resource cannot be exercised at all.

Describe "AzDoTestSuite Integration Tests" -Tag "Integration", "TestManagement" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TESTSUITE'
        $PLANNAME    = 'DSC_TEST_SUITE_PLAN'

        $planParameters = @{
            Name       = 'AzDoTestPlan'
            ModuleName = 'AzureDevOpsDscNative'
            Method     = 'Set'
            property   = @{
                ProjectName = $PROJECTNAME
                Name        = $PLANNAME
            }
        }

        $parameters = @{
            Name       = 'AzDoTestSuite'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                ProjectName = $PROJECTNAME
                PlanName    = $PLANNAME
                Path        = 'Regression'
                SuiteType   = 'StaticTestSuite'
            }
        }

        New-TestProject -ProjectName $PROJECTNAME

        $script:accessRefused = $false

        try
        {
            Invoke-DscResource @planParameters
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

    Context "Testing if the test suite exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the test suite" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (test suite does not exist yet)" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the test suite" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the test suite" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the test suite" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Re-testing an unchanged test suite" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should remain in the desired state when tested repeatedly" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Creating a dynamic child suite and re-testing its WIQL" {

        BeforeAll {
            $dynamicParameters = @{
                Name       = 'AzDoTestSuite'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    ProjectName = $PROJECTNAME
                    PlanName    = $PLANNAME
                    Path        = 'Regression/Active Bugs'
                    SuiteType   = 'DynamicTestSuite'
                    Wiql        = "select [System.Id] from WorkItems where [System.WorkItemType] = 'Bug' and [System.State] = 'Active'"
                }
            }
        }

        It "Should create the dynamic suite" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $dynamicParameters.Method = 'Set'
            { Invoke-DscResource @dynamicParameters } | Should -Not -Throw
        }

        It "Should not report drift even though the API reformats the WIQL it stores" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $dynamicParameters.Method = 'Test'
            (Invoke-DscResource @dynamicParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Ignoring an unbound property" {

        It "Should ignore RequirementIds when it is not bound" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $altParameters = @{
                Name       = 'AzDoTestSuite'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    ProjectName = $PROJECTNAME
                    PlanName    = $PLANNAME
                    Path        = 'Regression'
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Refusing to remove a suite that still has children" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName          = $PROJECTNAME
                PlanName             = $PLANNAME
                Path                 = 'Regression'
                AllowRecursiveDelete = $false
                Ensure               = 'Absent'
            }
        }

        It "Should leave the suite in place when AllowRecursiveDelete is false" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            try { Invoke-DscResource @parameters } catch { }

            $checkParameters = @{
                Name       = 'AzDoTestSuite'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Get'
                property   = @{
                    ProjectName = $PROJECTNAME
                    PlanName    = $PLANNAME
                    Path        = 'Regression'
                }
            }
            (Invoke-DscResource @checkParameters).Ensure | Should -Be 'Present'
        }
    }

    Context "Removing the suite tree recursively" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName          = $PROJECTNAME
                PlanName             = $PLANNAME
                Path                 = 'Regression'
                AllowRecursiveDelete = $true
                Ensure               = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the suite tree" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (test suite absent is the desired state)" {
            if ($script:accessRefused) { Set-ItResult -Skipped -Because 'the test identity has no Test Plans license/access in this organization' }

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
