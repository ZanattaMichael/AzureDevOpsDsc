Describe "AzDoProjectGroup DSC v3 Integration Tests" -Tag "V3", "Integration", "ProjectGroup" {

    BeforeAll {
        # Dot-source the helpers here rather than relying on the runner's dot-source:
        # Pester runs test files in their own session state, so functions defined in the
        # runner's script scope are not guaranteed to resolve from inside a test.
        . (Join-Path -Path $PSScriptRoot -ChildPath '..\Supporting\V3TestHelpers.ps1')

        $PROJECTNAME = 'V3_TESTPROJECT_PROJGROUP'
        $GROUPNAME   = 'V3-Test-ProjectGroup'

        # Create the host project via v2 DSC.
        Invoke-DscResource -Name AzDoProject -ModuleName AzureDevOpsDscNative -Method Set -Property @{
            ProjectName = $PROJECTNAME
        } -ErrorAction Stop

        Start-Sleep -Seconds 15

        $baseProps = @{
            ProjectName = $PROJECTNAME
            GroupName   = $GROUPNAME
        }
    }

    AfterAll {
        Invoke-DscResource -Name AzDoProject -ModuleName AzureDevOpsDscNative -Method Set -Property @{
            ProjectName = $PROJECTNAME
            Ensure      = 'Absent'
        } -ErrorAction SilentlyContinue
    }

    # -----------------------------------------------------------------------
    Context "Group does not exist yet" {

        It "Get returns a result without throwing" {
            { Invoke-DscV3Resource -ResourceName AzDoProjectGroup -Method Get -Property $baseProps } |
                Should -Not -Throw
        }

        It "Test reports not in desired state" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoProjectGroup -Property $baseProps
            $inState | Should -BeFalse
        }
    }

    # -----------------------------------------------------------------------
    Context "Creating the group" {

        It "Set does not throw" {
            { Invoke-DscV3Resource -ResourceName AzDoProjectGroup -Method Set -Property $baseProps } |
                Should -Not -Throw
        }

        It "Test reports in desired state after creation" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoProjectGroup -Property $baseProps
            $inState | Should -BeTrue
        }

        It "Get returns result without throwing" {
            { Invoke-DscV3Resource -ResourceName AzDoProjectGroup -Method Get -Property $baseProps } |
                Should -Not -Throw
        }
    }

    # -----------------------------------------------------------------------
    Context "Updating the group description" {

        BeforeAll {
            $script:updatedProps = @{
                ProjectName      = $PROJECTNAME
                GroupName        = $GROUPNAME
                GroupDescription = 'Added by DSC v3 integration test'
            }
        }

        It "Set with description does not throw" {
            { Invoke-DscV3Resource -ResourceName AzDoProjectGroup -Method Set `
                    -Property $script:updatedProps } |
                Should -Not -Throw
        }

        It "Test reports in desired state with description" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoProjectGroup `
                            -Property $script:updatedProps
            $inState | Should -BeTrue
        }
    }

    # -----------------------------------------------------------------------
    Context "Removing the group" {

        BeforeAll {
            $script:absentProps = @{
                ProjectName = $PROJECTNAME
                GroupName   = $GROUPNAME
                Ensure      = 'Absent'
            }
        }

        It "Set with Ensure=Absent does not throw" {
            { Invoke-DscV3Resource -ResourceName AzDoProjectGroup -Method Set `
                    -Property $script:absentProps } |
                Should -Not -Throw
        }

        It "Test reports in desired state after deletion" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoProjectGroup `
                            -Property $script:absentProps
            $inState | Should -BeTrue
        }
    }
}
