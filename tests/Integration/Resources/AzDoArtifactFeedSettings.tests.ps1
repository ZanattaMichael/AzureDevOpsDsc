Describe "AzDoArtifactFeedSettings Integration Tests" -Tag "Integration", "ArtifactFeedSettings" {

    BeforeAll {

        $PROJECTNAME = 'TEST_ARTIFACT_FEED_SETTINGS'
        # Azure DevOps reserves a feed name for a cooldown period after deletion — use a unique name.
        $FEEDNAME = "testfeedsettings$(Get-Random -Maximum 99999)"

        New-TestProject -ProjectName $PROJECTNAME

        # Settings require an existing feed — create one via the AzDoArtifactFeed resource first.
        Invoke-DscResource -Name 'AzDoArtifactFeed' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
            ProjectName = $PROJECTNAME
            FeedName    = $FEEDNAME
            Description = 'Feed used for feed-settings integration tests'
        }

        $parameters = @{
            Name       = 'AzDoArtifactFeedSettings'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName                          = $PROJECTNAME
                FeedName                             = $FEEDNAME
                HideDeletedPackageVersions           = $true
                RetentionCountLimit                  = 100
                DaysToKeepRecentlyDownloadedPackages = 30
            }
        }
    }

    Context "Testing if the feed settings are in desired state" {

        BeforeAll { $parameters.Method = 'Test' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }
    }

    Context "Applying the feed settings" {

        BeforeAll { $parameters.Method = 'Set' }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after applying the settings" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Updating the hide-deleted-package-versions setting" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.HideDeletedPackageVersions = $false
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

    Context "Removing the feed settings (no-op — settings cannot be removed)" {

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

        It "Should return True (Absent is a no-op for this resource)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
