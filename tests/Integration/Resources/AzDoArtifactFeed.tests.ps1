Describe "AzDoArtifactFeed Integration Tests" -Tag "Integration", "ArtifactFeed" {

    BeforeAll {

        $PROJECTNAME = 'TEST_ARTIFACT_FEED'
        # Azure DevOps reserves a feed name for a cooldown period after the feed is permanently
        # deleted (even once it is gone from the recycle bin), so reusing a fixed name across runs
        # fails with "feed name is currently reserved". Use a unique name per run for isolation.
        $FEEDNAME = "testfeed$(Get-Random -Maximum 99999)"

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        $parameters = @{
            Name       = 'AzDoArtifactFeed'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName              = $PROJECTNAME
                FeedName                 = $FEEDNAME
                Description              = 'Test artifact feed'
                BadgesEnabled            = $false
                HideDeletedPackageVersions = $true
                UpstreamEnabled          = $false
            }
        }

        New-Project $PROJECTNAME
    }

    Context "Testing if the artifact feed exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (feed does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the artifact feed" {

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

    Context "Updating the artifact feed" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Description   = 'Updated test artifact feed'
            $parameters.property.BadgesEnabled = $true
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

    Context "Removing the artifact feed" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                FeedName    = $FEEDNAME
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
