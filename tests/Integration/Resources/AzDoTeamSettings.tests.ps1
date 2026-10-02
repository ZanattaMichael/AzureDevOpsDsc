Describe "AzDoTeamSettings Integration Tests" -Tag "Integration", "TeamSettings" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TEAMSETTINGS'
        $TEAMNAME    = 'TESTTEAMSETTINGS'

        New-TestProject -ProjectName $PROJECTNAME

        # Team settings require an existing team — create one via the AzDoTeam resource first.
        Invoke-DscResource -Name 'AzDoTeam' -ModuleName 'AzureDevOpsDscNative' -Method 'Set' -Property @{
            ProjectName = $PROJECTNAME
            TeamName    = $TEAMNAME
            Description = 'Team used for team-settings integration tests'
        }

        $parameters = @{
            Name       = 'AzDoTeamSettings'
            ModuleName = 'AzureDevOpsDscNative'
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

    Context "Applying BacklogVisibilities" {

        BeforeAll {
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                TeamName            = $TEAMNAME
                BacklogVisibilities = @{
                    'Microsoft.EpicCategory'    = $false
                    'Microsoft.FeatureCategory' = $true
                }
            }
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after applying the stated categories" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should have written both stated categories directly on the live team, via the REST API" {
            $org     = Resolve-TestOrg
            $headers = Resolve-TestAuthHeader

            $projectId = (Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/projects/$PROJECTNAME`?api-version=7.1-preview.4" -Headers $headers).id
            $teamId    = (Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/projects/$PROJECTNAME/teams/$TEAMNAME`?api-version=7.1-preview.3" -Headers $headers).id

            $settings = Invoke-RestMethod -Uri "https://dev.azure.com/$org/$projectId/$teamId/_apis/work/teamsettings?api-version=7.1" -Headers $headers

            $settings.backlogVisibilities.'Microsoft.EpicCategory'    | Should -BeFalse
            $settings.backlogVisibilities.'Microsoft.FeatureCategory' | Should -BeTrue
        }

        It "Should not report drift for a category the configuration never mentions" {
            # Only the categories the configuration states are compared - a category the live team
            # has (e.g. Microsoft.RequirementCategory, left untouched above) is not read as drift
            # just because this configuration's hashtable omits it.
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                TeamName            = $TEAMNAME
                BacklogVisibilities = @{ 'Microsoft.EpicCategory' = $false }
            }
            $parameters.Method = 'Test'

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }

        It "Should report drift when a stated category's value no longer matches" {
            $parameters.property = @{
                ProjectName         = $PROJECTNAME
                TeamName            = $TEAMNAME
                BacklogVisibilities = @{ 'Microsoft.EpicCategory' = $true }
            }
            $parameters.Method = 'Test'

            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
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
