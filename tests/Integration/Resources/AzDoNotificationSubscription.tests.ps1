Describe "AzDoNotificationSubscription Integration Tests (work item changed, Email channel)" {

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

    Context "Testing if the work item changed notification subscription exists" {

        BeforeAll {
            $parameters.Method = 'Test'
        }

        It "Should not throw any exceptions when testing the work item changed notification subscription" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return False (work item changed notification subscription does not exist yet)" {
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeFalse
        }
    }

    Context "Creating the work item changed notification subscription" {

        BeforeAll {
            $parameters.Method = 'Set'
        }

        It "Should not throw any exceptions when creating the work item changed notification subscription" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after creating the work item changed notification subscription" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Disabling the work item changed notification subscription" {

        BeforeAll {
            $parameters.Method = 'Set'
            $parameters.property.Enabled = $false
        }

        It "Should not throw any exceptions when disabling the work item changed notification subscription" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True after disabling the work item changed notification subscription" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }

    Context "Removing the work item changed notification subscription" {

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

        It "Should not throw any exceptions when removing the work item changed notification subscription" {
            { Invoke-DscResource @parameters } | Should -Not -Throw
        }

        It "Should return True (work item changed notification subscription absent is the desired state)" {
            $parameters.Method = 'Test'
            $result = Invoke-DscResource @parameters
            $result.InDesiredState | Should -BeTrue
        }
    }
}
