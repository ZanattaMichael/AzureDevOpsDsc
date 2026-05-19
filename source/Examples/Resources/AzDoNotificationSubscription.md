# DSC AzDoNotificationSubscription Resource

# Syntax

``` PowerShell
AzDoNotificationSubscription [string] #ResourceName
{
    SubscriptionName  = [String]$SubscriptionName
    EventType         = [String]$EventType
    ChannelType       = [String]$ChannelType
    Subscriber        = [String]$Subscriber
    [ ProjectName     = [String]$ProjectName ]
    [ Filter          = [HashTable]$Filter ]
    [ Enabled         = [Boolean]$Enabled ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __SubscriptionName__: A descriptive name for the subscription. This is a key property.
- __EventType__: The type of event to subscribe to. This is a key property. Common values include:
  - `ms.vss-build.build-completed-failed-id` - Build failure
  - `ms.vss-build.build-completed-id` - Build completion
  - `ms.vss-code.git-push` - Code push
  - `ms.vss-code.git-pullrequest-created` - Pull request created
- __ChannelType__: The delivery channel for notifications. Common values: `EmailHtml`, `EmailPlainText`, `Slack`.
- __Subscriber__: The email address or group descriptor of the notification recipient.
- __ProjectName__: The project to scope the subscription to. If omitted, applies organization-wide.
- __Filter__: A hashtable specifying event filter criteria.
- __Enabled__: Whether the subscription is active. Defaults to `$true`.
- __Ensure__: Specifies whether the subscription should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages Azure DevOps notification subscriptions, which deliver alerts about project events (builds, pull requests, work items, etc.) to email addresses, Slack channels, or other subscribers.

# Examples

## Example 1: Subscribe to build failures

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoNotificationSubscription 'BuildFailureNotification' {
            Ensure           = 'Present'
            SubscriptionName = 'BuildFailureAlert'
            EventType        = 'ms.vss-build.build-completed-failed-id'
            ChannelType      = 'EmailHtml'
            Subscriber       = 'team@example.com'
            ProjectName      = 'MyProject'
            Enabled          = $true
        }
    }
}
```

## Example 2: Subscribe to pull request creation

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoNotificationSubscription 'PullRequestNotification' {
            Ensure           = 'Present'
            SubscriptionName = 'NewPullRequestAlert'
            EventType        = 'ms.vss-code.git-pullrequest-created'
            ChannelType      = 'EmailHtml'
            Subscriber       = 'reviewers@example.com'
            ProjectName      = 'MyProject'
            Enabled          = $true
        }
    }
}
```
