Describe "AzDoWiki Integration Tests" {

    BeforeAll {

        $PROJECTNAME = 'TEST_WIKI'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        $parameters = @{
            Name       = 'AzDoWiki'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName = $PROJECTNAME
                WikiName    = 'TEST_PROJECTWIKI'
                WikiType    = 'projectWiki'
            }
        }

        New-Project $PROJECTNAME
    }

    Context "Testing if the wiki exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (wiki does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the wiki" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the wiki" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                WikiName    = 'TEST_PROJECTWIKI'
                WikiType    = 'projectWiki'
                Ensure      = 'Absent'
            }
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
