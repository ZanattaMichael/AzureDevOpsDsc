Describe "AzDoNotificationSubscription Integration Tests" {

    BeforeAll {

        $PROJECTNAME = 'TEST_NOTIFICATION'

        function New-Project { param([string]$ProjectName)
            $null = Invoke-DscResource -Name 'AzDoProject' -ModuleName 'AzureDevOpsDsc' -Method 'Set' -Property @{ ProjectName = $ProjectName }
        }

        # Use a project-scoped work-item changed event with a group email channel.
        # The subscriber identity must be a valid group/user descriptor in the org.
        # Using the built-in "[ProjectName]\Build Service (OrgName)" identity would
        # require knowing the org name at test time, so we use the project Contributors
        # group which is always present.
        $parameters = @{
            Name       = 'AzDoNotificationSubscription'
            ModuleName = 'AzureDevOpsDsc'
            property   = @{
                SubscriptionName = 'TEST_WI_CHANGED'
                EventType        = 'ms.vss-work.workitem-changed-event'
                ChannelType      = 'EmailHtml'
                Subscriber       = "[$PROJECTNAME]\Contributors"
                ProjectName      = $PROJECTNAME
                Enabled          = $true
            }
        }

        New-Project $PROJECTNAME
    }

    Context "Testing if the notification subscription exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (subscription does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the notification subscription" {

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

    Context "Disabling the notification subscription" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Enabled = $false
        }

        It "Should not throw any exceptions" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after disabling" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the notification subscription" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property = @{
                SubscriptionName = 'TEST_WI_CHANGED'
                EventType        = 'ms.vss-work.workitem-changed-event'
                ChannelType      = 'EmailHtml'
                Subscriber       = "[$PROJECTNAME]\Contributors"
                Ensure           = 'Absent'
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
