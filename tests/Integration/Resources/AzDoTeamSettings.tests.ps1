Describe "AzDoTeamSettings Integration Tests" -Tag "Integration", "TeamSettings" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TEAMSETTINGS'
        $TEAMNAME    = 'TESTTEAMSETTINGS'

        New-TestProject -ProjectName $PROJECTNAME

        # Team settings require an existing team — create one via the AzDoTeam resource first.
        Invoke-DscResource -Name 'AzDoTeam' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
            ProjectName = $PROJECTNAME
            TeamName    = $TEAMNAME
            Description = 'Team used for team-settings integration tests'
        }

        $parameters = @{
            Name       = 'AzDoTeamSettings'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName  = $PROJECTNAME
                TeamName     = $TEAMNAME
                DefaultAreaPath = $PROJECTNAME
                WorkingDays  = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
                BugsBehavior = 'asRequirements'
            }
        }
    }

    Context "Testing if the team settings are in desired state" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Applying the team settings" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after applying the settings" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the bugs behavior" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.BugsBehavior = 'asTasks'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after update" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the team settings (no-op — settings cannot be removed)" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                TeamName    = $TEAMNAME
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is a no-op for this resource)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
