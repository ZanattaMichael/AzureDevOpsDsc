Describe "AzDoArtifactFeed Integration Tests" -Tag "Integration", "ArtifactFeed" {

    BeforeAll {

        $PROJECTNAME = 'TEST_ARTIFACT_FEED'
        # Azure DevOps reserves a feed name for a cooldown period after deletion.
        # Use a unique name per run to avoid "feed name reserved" conflicts.
        $FEEDNAME = "testfeed$(Get-Random -Maximum 99999)"

        $authHeader = New-TestAuthHeader
        $ORG        = Get-TestOrganizationName

        New-TestProject -Organization $ORG -ProjectName $PROJECTNAME -AuthHeader $authHeader

        $parameters = @{
            Name       = 'AzDoArtifactFeed'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName                = $PROJECTNAME
                FeedName                   = $FEEDNAME
                Description                = 'Test artifact feed'
                BadgesEnabled              = $false
                HideDeletedPackageVersions = $true
                UpstreamEnabled            = $false
            }
        }
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
