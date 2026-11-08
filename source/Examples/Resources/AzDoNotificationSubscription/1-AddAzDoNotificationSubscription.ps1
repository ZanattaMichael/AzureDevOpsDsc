<#
    .DESCRIPTION
        This example shows how to create a notification subscription in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
