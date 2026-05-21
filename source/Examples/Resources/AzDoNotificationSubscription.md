# DSC AzDoNotificationSubscription Resource

## Syntax

```PowerShell
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

## Properties

### Common Properties

- **SubscriptionName**: A descriptive name for the subscription. This property is mandatory and serves as a key property for the resource.
- **EventType**: The type of event to subscribe to. This is a key property. Common values include `ms.vss-build.build-completed-failed-id`, `ms.vss-code.git-push`, and `ms.vss-code.git-pullrequest-created`.
- **ChannelType**: The delivery channel for notifications. Common values: `EmailHtml`, `EmailPlainText`.
- **Subscriber**: The email address or group descriptor of the notification recipient. This is a mandatory property.
- **ProjectName**: The project to scope the subscription to. If omitted, applies organization-wide.
- **Filter**: A hashtable specifying event filter criteria.
- **Enabled**: Whether the subscription is active. Defaults to `$true`.
- **Ensure**: Specifies whether the subscription should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages Azure DevOps notification subscriptions, which deliver alerts about project events (builds, pull requests, work items, etc.) to email addresses or other subscribers.

## Examples

## Example 1: Sample Configuration using AzDoNotificationSubscription Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoNotificationSubscription BuildFailureNotification {
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

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoNotificationSubscription
$properties = @{
    SubscriptionName = 'BuildFailureAlert'
    EventType        = 'ms.vss-build.build-completed-failed-id'
}

Invoke-DscResource -Name 'AzDoNotificationSubscription' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Build Failure Alert
  type: AzureDevOpsDsc/AzDoNotificationSubscription
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    SubscriptionName: BuildFailureAlert
    EventType: ms.vss-build.build-completed-failed-id
    ChannelType: EmailHtml
    Subscriber: team@example.com
    ProjectName: $ProjectName
    Enabled: true
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
