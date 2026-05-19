# DSC AzDoAuditStream Resource

# Syntax

``` PowerShell
AzDoAuditStream [string] #ResourceName
{
    StreamName      = [String]$StreamName
    ConsumerType    = [String] {'AzureMonitorLogs', 'Splunk', 'AzureEventGrid', 'AzureEventHub'}
    ConsumerInputs  = [HashTable]$ConsumerInputs
    [ Enabled       = [Boolean]$Enabled ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __StreamName__: The name of the audit stream. This is a key property.
- __ConsumerType__: The type of audit log consumer. Valid values are `AzureMonitorLogs`, `Splunk`, `AzureEventGrid`, and `AzureEventHub`.
- __ConsumerInputs__: A hashtable of configuration inputs specific to the consumer type.
- __Enabled__: Whether the audit stream is active. Defaults to `$true`.
- __Ensure__: Specifies whether the audit stream should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## ConsumerInputs Examples by Type

### AzureEventHub
``` PowerShell
ConsumerInputs = @{
    connectionString = 'Endpoint=sb://my-eventhub.servicebus.windows.net/;SharedAccessKeyName=...'
    eventHubName     = 'audit-logs'
}
```

### Splunk
``` PowerShell
ConsumerInputs = @{
    splunkEventCollectorUrl = 'https://splunk-host:8088'
    splunkEventCollectorToken = 'my-hec-token'
}
```

# Additional Information

This resource manages audit streams that forward Azure DevOps audit events to external SIEM or monitoring systems. Audit streams help organizations meet compliance and security monitoring requirements.

# Examples

## Example 1: Create an Audit Stream to Azure Event Hub

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAuditStream 'AddAuditStream' {
            Ensure         = 'Present'
            StreamName     = 'MyEventHubAuditStream'
            ConsumerType   = 'AzureEventHub'
            ConsumerInputs = @{
                connectionString = 'Endpoint=sb://my-eventhub.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=xxxx'
                eventHubName     = 'azdo-audit-logs'
            }
            Enabled        = $true
        }
    }
}
```

## Example 2: Remove an Audit Stream

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAuditStream 'RemoveAuditStream' {
            Ensure         = 'Absent'
            StreamName     = 'MyEventHubAuditStream'
            ConsumerType   = 'AzureEventHub'
            ConsumerInputs = @{}
        }
    }
}
```
