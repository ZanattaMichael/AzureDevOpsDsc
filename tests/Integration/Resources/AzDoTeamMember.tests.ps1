Describe "AzDoTeamMember Integration Tests" -Tag "Integration", "TeamMember" {

    BeforeAll {

        $PROJECTNAME = 'TEST_TEAMMEMBER'
        $TEAMNAME    = 'TESTTEAM_MEMBER'
        $GROUPNAME   = 'TESTGROUP_MEMBER'

        function New-Team { param([string]$ProjectName, [string]$TeamName)
            $null = Invoke-DscResource -Name 'AzDoTeam' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                TeamName    = $TeamName
            }
        }

        $parameters = @{
            Name       = 'AzDoTeamMember'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName = $PROJECTNAME
                TeamName    = $TEAMNAME
                MemberName  = "[$PROJECTNAME]\$GROUPNAME"
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-Team -ProjectName $PROJECTNAME -TeamName $TEAMNAME
        New-TestGroup -ProjectName $PROJECTNAME -GroupName $GROUPNAME
    }

    Context "Testing if the team member exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (member not yet added)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Adding the team member" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after adding the member" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the team member" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Ensure = 'Absent'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (Absent is desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
