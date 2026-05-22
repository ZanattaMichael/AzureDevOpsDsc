<#
    .DESCRIPTION
        This example shows how to update a notification subscription in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoNotificationSubscription 'UpdateAzDoNotificationSubscription'
        {
            Ensure           = 'Present'
            SubscriptionName = 'BuildFailureAlert'
            EventType        = 'ms.vss-build.build-completed-failed-id'
            ChannelType      = 'EmailHtml'
            Subscriber       = 'oncall@example.com'
            ProjectName      = 'MyProject'
            Enabled          = $true
            Filter           = @{
                criteria = @{
                    clauses = @(
                        @{ fieldName = 'Build reason'; operator = '='; value = 'Manual' }
                    )
                }
            }
        }
    }
}
