configuration Update_AzDoAuditStream
{
    Import-DscResource -ModuleName AzureDevOpsDsc

    AzDoAuditStream 'UpdateAuditStream'
    {
        StreamName     = 'MySlackAuditStream'
        ConsumerType   = 'Slack'
        ConsumerInputs = @{
            webhookUrl = 'https://hooks.slack.com/services/T000/B000/YYYY'
            channelId  = '#audit-updated'
        }
        Enabled        = $true
        Ensure         = 'Present'
    }
}