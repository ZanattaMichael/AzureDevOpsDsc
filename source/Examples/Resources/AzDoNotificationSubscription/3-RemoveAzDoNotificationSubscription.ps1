<#
    .DESCRIPTION
        This example shows how to remove a notification subscription from Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
