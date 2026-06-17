Describe "AzDoProjectGroup Integration Tests - No Description" -Tag "Integration", "ProjectGroup" {

    BeforeAll {

        $PROJECTNAME = 'TESTPROJECT_PROJECTGROUP_NODESC'
        $GROUPNAME   = 'TESTPROJECTGROUP_NODESC'

        $parameters = @{
            Name       = 'AzDoProjectGroup'
            ModuleName = 'AzureDevOpsDsc'
        }

        New-TestProject -ProjectName $PROJECTNAME

        # Ensure group does not exist before starting
        $null = Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
            ProjectName = $PROJECTNAME
            GroupName   = $GROUPNAME
            Ensure      = 'Absent'
        } -ErrorAction SilentlyContinue
    }

    Context "Testing if a Project Group Exists (no description)" {

        BeforeAll {
            $parameters.Method   = 'Test'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                GroupName   = $GROUPNAME
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False when group does not exist" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating a new Project Group without description" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                GroupName   = $GROUPNAME
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after creation" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the Project Group" {

        BeforeAll {
            $parameters.Method   = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                GroupName   = $GROUPNAME
                Ensure      = 'Absent'
            }
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should be in desired state after removal" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
