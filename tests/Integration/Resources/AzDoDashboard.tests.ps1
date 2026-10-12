Describe "AzDoDashboard Integration Tests" -Tag "Integration", "Dashboard" {

    BeforeAll {

        $PROJECTNAME   = 'TEST_DASHBOARD'
        # Every project is created with a default team named '<project> Team'.
        $TEAMNAME      = "$PROJECTNAME Team"
        $DASHBOARDNAME = 'DSC Team Dashboard'

        $parameters = @{
            Name       = 'AzDoDashboard'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                DashboardName = $DASHBOARDNAME
                ProjectName   = $PROJECTNAME
                TeamName      = $TEAMNAME
                Description   = 'Created by the AzDoDashboard integration test'
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
    }

    Context "Testing if the team dashboard exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions when testing the dashboard" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (dashboard does not exist yet)" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the team dashboard" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions when creating the dashboard" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the dashboard" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should remain in the desired state when tested repeatedly" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Settings not compared without being specified" {

        It "Should ignore Description and RefreshInterval when they are not set" {
            $altParameters = @{
                Name       = 'AzDoDashboard'
                ModuleName = 'AzureDevOpsDscNative'
                Method     = 'Test'
                property   = @{
                    DashboardName = $DASHBOARDNAME
                    ProjectName   = $PROJECTNAME
                    TeamName      = $TEAMNAME
                }
            }

            (Invoke-DscResource @altParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Drifting and fixing the description and refresh interval" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                DashboardName   = $DASHBOARDNAME
                ProjectName     = $PROJECTNAME
                TeamName        = $TEAMNAME
                Description     = 'Updated by the AzDoDashboard integration test'
                RefreshInterval = 5
            }
        }

        It "Should report drift" {
            (Invoke-DscResource @parameters).InDesiredState | Should -BeFalse
        }

        It "Should converge after Set" {
            $parameters.Method = 'Set'
            { Invoke-DscResource @parameters } | Should -Not -Throw

            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }

        It "Should keep the description when a later update manages only the refresh interval" {
            $refreshOnly = @{
                Name       = 'AzDoDashboard'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    DashboardName   = $DASHBOARDNAME
                    ProjectName     = $PROJECTNAME
                    TeamName        = $TEAMNAME
                    RefreshInterval = 0
                }
            }

            $refreshOnly.Method = 'Set'
            { Invoke-DscResource @refreshOnly } | Should -Not -Throw

            $refreshOnly.Method = 'Test'
            (Invoke-DscResource @refreshOnly).InDesiredState | Should -BeTrue

            $parameters.property.RefreshInterval = 0
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Managing a project-scoped dashboard" {

        BeforeAll {
            $projectParameters = @{
                Name       = 'AzDoDashboard'
                ModuleName = 'AzureDevOpsDscNative'
                property   = @{
                    DashboardName = 'DSC Project Dashboard'
                    ProjectName   = $PROJECTNAME
                }
            }
        }

        It "Should create the dashboard without a team" {
            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeFalse

            $projectParameters.Method = 'Set'
            { Invoke-DscResource @projectParameters } | Should -Not -Throw

            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeTrue
        }

        It "Should remove the dashboard" {
            $projectParameters.property.Ensure = 'Absent'

            $projectParameters.Method = 'Set'
            { Invoke-DscResource @projectParameters } | Should -Not -Throw

            $projectParameters.Method = 'Test'
            (Invoke-DscResource @projectParameters).InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the team dashboard" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                DashboardName = $DASHBOARDNAME
                ProjectName   = $PROJECTNAME
                TeamName      = $TEAMNAME
                Ensure        = 'Absent'
            }
        }

        It "Should not throw any exceptions when removing the dashboard" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (dashboard absent is the desired state)" {
            $parameters.Method = 'Test'
            (Invoke-DscResource @parameters).InDesiredState | Should -BeTrue
        }
    }
}
