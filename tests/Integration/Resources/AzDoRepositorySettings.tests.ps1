Describe "AzDoRepositorySettings Integration Tests" -Tag "Integration", "RepositorySettings" {

    BeforeAll {

        $PROJECTNAME = 'TEST_REPO_SETTINGS'
        $REPONAME    = 'TESTREPOSITORY_SETTINGS'

        $parameters = @{
            Name       = 'AzDoRepositorySettings'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName        = $PROJECTNAME
                RepositoryName     = $REPONAME
                DefaultBranch      = 'main'
                AllowSquashMerge   = $true
                AllowRebaseMerge   = $true
                AllowNoFastForward = $true
                DisableForking     = $false
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
        New-TestGitRepository -ProjectName $PROJECTNAME -RepositoryName $REPONAME
    }

    Context "Testing if the repository settings are in desired state" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Applying repository settings" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after applying settings" {
            Start-Sleep -Seconds 3
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing repository settings" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.AllowSquashMerge   = $false
            $parameters.property.AllowRebaseMerge   = $false
            $parameters.property.AllowNoFastForward = $true
            $parameters.property.DisableForking     = $true
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after changing settings" {
            Start-Sleep -Seconds 3
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Reverting repository settings to defaults" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.AllowSquashMerge   = $true
            $parameters.property.AllowRebaseMerge   = $true
            $parameters.property.AllowNoFastForward = $true
            $parameters.property.DisableForking     = $false
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after reverting" {
            Start-Sleep -Seconds 3
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
