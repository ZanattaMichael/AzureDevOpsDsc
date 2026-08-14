Describe "AzDoGitRepository DSC v3 Integration Tests" -Tag "V3", "Integration", "GitRepository" {

    BeforeAll {
        $PROJECTNAME = 'V3_TESTPROJECT_GITREPO'
        $REPONAME    = 'v3-test-repository'

        # Create the host project via v2 DSC (projects are a prerequisite for repo tests).
        Invoke-DscResource -Name AzDoProject -ModuleName AzureDevOpsDscNative -Method Set -Property @{
            ProjectName = $PROJECTNAME
        } -ErrorAction Stop

        Start-Sleep -Seconds 15

        $baseProps = @{
            ProjectName    = $PROJECTNAME
            RepositoryName = $REPONAME
        }
    }

    AfterAll {
        # Remove the host project after all repository tests complete.
        Invoke-DscResource -Name AzDoProject -ModuleName AzureDevOpsDscNative -Method Set -Property @{
            ProjectName = $PROJECTNAME
            Ensure      = 'Absent'
        } -ErrorAction SilentlyContinue
    }

    # -----------------------------------------------------------------------
    Context "Repository does not exist yet" {

        It "Get returns a result without throwing" {
            { Invoke-DscV3Resource -ResourceName AzDoGitRepository -Method Get -Property $baseProps } |
                Should -Not -Throw
        }

        It "Test reports not in desired state" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoGitRepository -Property $baseProps
            $inState | Should -BeFalse
        }
    }

    # -----------------------------------------------------------------------
    Context "Creating the repository" {

        BeforeAll {
            $script:createProps = $baseProps + @{ Ensure = 'Present' }
        }

        It "Set does not throw" {
            { Invoke-DscV3Resource -ResourceName AzDoGitRepository -Method Set `
                    -Property $script:createProps } |
                Should -Not -Throw
        }

        It "Test reports in desired state after creation" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoGitRepository `
                            -Property $script:createProps
            $inState | Should -BeTrue
        }

        It "Get returns result without throwing" {
            { Invoke-DscV3Resource -ResourceName AzDoGitRepository -Method Get `
                    -Property $script:createProps } |
                Should -Not -Throw
        }
    }

    # -----------------------------------------------------------------------
    Context "Removing the repository" {

        BeforeAll {
            $script:absentProps = @{
                ProjectName    = $PROJECTNAME
                RepositoryName = $REPONAME
                Ensure         = 'Absent'
            }
        }

        It "Set with Ensure=Absent does not throw" {
            { Invoke-DscV3Resource -ResourceName AzDoGitRepository -Method Set `
                    -Property $script:absentProps } |
                Should -Not -Throw
        }

        It "Test reports in desired state after deletion" {
            $inState = Test-DscV3InDesiredState -ResourceName AzDoGitRepository `
                            -Property $script:absentProps
            $inState | Should -BeTrue
        }
    }
}
