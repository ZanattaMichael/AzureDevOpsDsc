Describe "AzDoArtifactFeedPermission Integration Tests" -Tag "Integration", "ArtifactFeedPermission" {

    BeforeAll {

        $PROJECTNAME = 'TEST_FEED_PERM'
        $FEEDNAME    = 'testfeedperm'
        $GROUPNAME   = 'FeedPermGroup'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        function New-Feed { param([string]$ProjectName, [string]$FeedName)
            $null = Invoke-DscResource -Name 'AzDoArtifactFeed' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                FeedName    = $FeedName
            }
        }

        function New-Group { param([string]$ProjectName, [string]$GroupName)
            $null = Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{
                ProjectName = $ProjectName
                GroupName   = $GroupName
            }
        }

        $parameters = @{
            Name       = 'AzDoArtifactFeedPermission'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                ProjectName = $PROJECTNAME
                FeedName    = $FEEDNAME
                Permissions = @(
                    @{
                        Identity = "[$PROJECTNAME]\$GROUPNAME"
                        Role     = 'Reader'
                    }
                )
            }
        }

        New-Project $PROJECTNAME
        New-Feed -ProjectName $PROJECTNAME -FeedName $FEEDNAME
        New-Group -ProjectName $PROJECTNAME -GroupName $GROUPNAME
    }

    Context "Testing if feed permissions exist" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (permissions not yet set)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Setting feed permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after setting permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Changing feed permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @(
                @{
                    Identity = "[$PROJECTNAME]\$GROUPNAME"
                    Role     = 'Contributor'
                }
            )
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after changing permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing all explicit feed permissions" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Permissions = @()
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True with empty permissions" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
