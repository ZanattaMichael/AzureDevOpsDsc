# Creating an email-channel subscription with a custom delivery address requires that address to
# belong to a REAL user in the organization's Microsoft Entra ID tenant (Azure DevOps rejects any
# other address with "cannot be used for notification delivery because it does not belong to a
# user in this organization's Microsoft Entra ID tenant"). There is no safe placeholder address for
# this, and the principal name is PII - this is a public repository, so it is NEVER hard-coded here.
# It is supplied at run time via the AZDODSC_TEST_USER_UPN environment variable (the same one used
# by AzDoUserEntitlement.tests.ps1; set it as a SECRET / masked pipeline variable in CI so the value
# is redacted from logs). When it is not set the tests are skipped.
#
#   # locally:
#   $env:AZDODSC_TEST_USER_UPN = '<disposable-test-account-upn>'

$TEST_USER = $env:AZDODSC_TEST_USER_UPN
$skipNotificationSubscription = [string]::IsNullOrWhiteSpace($TEST_USER)

Describe "AzDoNotificationSubscription Integration Tests (work item changed, Email channel)" -Tag "Integration", "NotificationSubscription" -Skip:$skipNotificationSubscription {

    BeforeAll {

        $PROJECTNAME = 'TEST_NOTIFICATION'
        $TEST_USER = $env:AZDODSC_TEST_USER_UPN

        # Use a project-scoped work-item changed event with an email channel. Subscriber is the
        # literal channel destination address (see Get-AzDoNotificationSubscription/New-AzDoNotificationSubscription
        # unit tests and Examples/Resources/AzDoNotificationSubscription) - it is passed straight
        # through to the API's channel.address with useCustomAddress set, so it must be a real user
        # in the organization's tenant.
        $parameters = @{
            Name       = 'AzDoNotificationSubscription'
            ModuleName = 'AzureDevOpsDscNative'
            property   = @{
                SubscriptionName = 'TEST_WI_CHANGED'
                EventType        = 'ms.vss-work.workitem-changed-event'
                ChannelType      = 'EmailHtml'
                Subscriber       = $TEST_USER
                ProjectName      = $PROJECTNAME
                Enabled          = $true
            }
        }

        New-TestProject -ProjectName $PROJECTNAME
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
                Subscriber       = $TEST_USER
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
