configuration Add_AzDoAuditStream
{
    Import-DscResource -ModuleName AzureDevOpsDsc

    AzDoAuditStream 'AddAuditStream'
    {
        StreamName     = 'MySlackAuditStream'
        ConsumerType   = 'Slack'
        ConsumerInputs = @{
            webhookUrl = 'https://hooks.slack.com/services/T000/B000/XXXX'
            channelId  = '#audit'
        }
        Enabled        = $true
        Ensure         = 'Present'
    }
}