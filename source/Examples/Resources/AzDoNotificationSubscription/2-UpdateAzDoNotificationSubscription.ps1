<#
    .DESCRIPTION
        This example shows how to update a notification subscription in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
