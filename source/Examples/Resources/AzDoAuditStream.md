# DSC AzDoAuditStream Resource

## Syntax

```PowerShell
AzDoAuditStream [string] #ResourceName
{
    StreamName     = [String]$StreamName
    ConsumerType   = [String] {'AzureMonitorLogs', 'Splunk', 'AzureEventGrid', 'AzureEventHub'}
    ConsumerInputs = [HashTable]$ConsumerInputs
    [ Enabled      = [Boolean]$Enabled ]
    [ Ensure       = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **StreamName**: The name of the audit stream. This property is mandatory and serves as the key property for the resource.
- **ConsumerType**: The type of audit log consumer. Valid values are `AzureMonitorLogs`, `Splunk`, `AzureEventGrid`, and `AzureEventHub`.
- **ConsumerInputs**: A hashtable of configuration inputs specific to the consumer type.
- **Enabled**: Whether the audit stream is active. Defaults to `$true`.
- **Ensure**: Specifies whether the audit stream should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages audit streams that forward Azure DevOps audit events to external SIEM or monitoring systems. Audit streams help organizations meet compliance and security monitoring requirements.

## Examples

## Example 1: Sample Configuration using AzDoAuditStream Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAuditStream AddAuditStream {
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

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoAuditStream
$properties = @{
    StreamName     = 'MyEventHubAuditStream'
    ConsumerType   = 'AzureEventHub'
    ConsumerInputs = @{
        connectionString = 'Endpoint=sb://my-eventhub.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=xxxx'
        eventHubName     = 'azdo-audit-logs'
    }
}

Invoke-DscResource -Name 'AzDoAuditStream' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  StreamName: MyEventHubAuditStream
}

resources:
- name: Azure Event Hub Audit Stream
  type: AzureDevOpsDsc/AzDoAuditStream
  properties:
    StreamName: $StreamName
    ConsumerType: AzureEventHub
    ConsumerInputs:
      connectionString: 'Endpoint=sb://my-eventhub.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=xxxx'
      eventHubName: azdo-audit-logs
    Enabled: true
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
