<#
    .DESCRIPTION
        This example shows how to remove a notification subscription from Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoNotificationSubscription 'RemoveAzDoNotificationSubscription'
        {
            Ensure           = 'Absent'
            SubscriptionName = 'BuildFailureAlert'
            EventType        = 'ms.vss-build.build-completed-failed-id'
        }
    }
}
