Describe "AzDoProject DSC v3 Integration Tests" -Tag "V3", "Integration", "Project" {

    BeforeAll {
        # V3TestHelpers.ps1 is dot-sourced by the runner; all three helper functions are available.
        $PROJECTNAME = 'V3_TESTPROJECT'

        $baseProps = @{
            ProjectName        = $PROJECTNAME
            ProjectDescription = 'DSC v3 integration test project'
        }
    }

    # -----------------------------------------------------------------------
    Context "Project does not exist yet" {

        It "Get returns an Absent-equivalent result without throwing" {
            { Invoke-DscV3Resource -ResourceName AzDoProject -Method Get -Property $baseProps } |
                Should -Not -Throw
        }

        It "Test reports not in desired state" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoProject -Property $baseProps
            $inState | Should -BeFalse
        }
    }

    # -----------------------------------------------------------------------
    Context "Creating the project" {

        It "Set does not throw" {
            { Invoke-DscV3Resource -ResourceName AzDoProject -Method Set -Property $baseProps } |
                Should -Not -Throw
        }

        It "Test reports in desired state after creation" {
            # Azure DevOps project creation is asynchronous — give it a moment.
            Start-Sleep -Seconds 15
            $inState = Test-DscV3InDesiredState -ResourceName AzDoProject -Property $baseProps
            $inState | Should -BeTrue
        }

        It "Get returns result without throwing" {
            { Invoke-DscV3Resource -ResourceName AzDoProject -Method Get -Property $baseProps } |
                Should -Not -Throw
        }
    }

    # -----------------------------------------------------------------------
    Context "Updating the project description" {

        BeforeAll {
            $script:updatedProps = @{
                ProjectName        = $PROJECTNAME
                ProjectDescription = 'Updated by DSC v3 integration test'
            }
        }

        It "Set with new description does not throw" {
            { Invoke-DscV3Resource -ResourceName AzDoProject -Method Set -Property $script:updatedProps } |
                Should -Not -Throw
        }

        It "Test reports in desired state with new description" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoProject -Property $script:updatedProps
            $inState | Should -BeTrue
        }
    }

    # -----------------------------------------------------------------------
    Context "Removing the project" {

        BeforeAll {
            $script:absentProps = @{
                ProjectName = $PROJECTNAME
                Ensure      = 'Absent'
            }
        }

        It "Set with Ensure=Absent does not throw" {
            { Invoke-DscV3Resource -ResourceName AzDoProject -Method Set -Property $script:absentProps } |
                Should -Not -Throw
        }

        It "Test reports in desired state after deletion" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoProject -Property $script:absentProps
            $inState | Should -BeTrue
        }
    }
}
