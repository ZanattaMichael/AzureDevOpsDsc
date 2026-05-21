<#
    .DESCRIPTION
        This example shows how to create a notification subscription in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoNotificationSubscription 'AddAzDoNotificationSubscription'
        {
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
