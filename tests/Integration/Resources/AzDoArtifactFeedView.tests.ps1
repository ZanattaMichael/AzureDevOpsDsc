Describe "AzDoArtifactFeedView Integration Tests" -Tag "Integration", "ArtifactFeedView" {

    BeforeAll {

        $PROJECTNAME = 'TEST_ARTIFACT_FEED_VIEW'
        # Azure DevOps reserves a feed name for a cooldown period after deletion — use a unique name.
        $FEEDNAME = "testfeedview$(Get-Random -Maximum 99999)"
        $VIEWNAME = 'IntegrationView'

        New-TestProject -ProjectName $PROJECTNAME

        # Views require an existing feed — create one via the AzDoArtifactFeed resource first.
        Invoke-DscResource -Name 'AzDoArtifactFeed' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
            ProjectName = $PROJECTNAME
            FeedName    = $FEEDNAME
            Description = 'Feed used for feed-view integration tests'
        }

        $parameters = @{
            Name       = 'AzDoArtifactFeedView'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName    = $PROJECTNAME
                FeedName       = $FEEDNAME
                ViewName       = $VIEWNAME
                ViewType       = 'release'
                ViewVisibility = 'collection'
            }
        }
    }

    Context "Testing if the view exists" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (view does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the view" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creation" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the view visibility" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.ViewVisibility = 'organization'
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

    Context "Removing the view" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                ProjectName = $PROJECTNAME
                FeedName    = $FEEDNAME
                ViewName    = $VIEWNAME
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
