configuration Remove_AzDoAuditStream
{
    Import-DscResource -ModuleName AzureDevOpsDscNative

    AzDoAuditStream 'RemoveAuditStream'
    {
        StreamName     = 'MySlackAuditStream'
        ConsumerType   = 'Slack'
        ConsumerInputs = @{
            webhookUrl = 'https://hooks.slack.com/services/T000/B000/XXXX'
        }
        Ensure         = 'Absent'
    }
}