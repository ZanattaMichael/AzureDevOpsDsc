# DSC AzDoServiceHook Resource

## Syntax

```PowerShell
AzDoServiceHook [string] #ResourceName
{
    Name               = [String]$Name
    PublisherId        = [String]$PublisherId
    EventType          = [String]$EventType
    ConsumerId         = [String]$ConsumerId
    ConsumerActionId   = [String]$ConsumerActionId
    [ ProjectName      = [String]$ProjectName ]
    [ ConsumerInputs   = [HashTable]$ConsumerInputs ]
    [ PublisherInputs  = [HashTable]$PublisherInputs ]
    [ ResourceVersion  = [String]$ResourceVersion ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **Name**: A logical name for the subscription. This is the key property and is **not** sent to Azure DevOps — service hook subscriptions have no native name, so the live subscription is matched by its identity tuple (`PublisherId` + `EventType` + `ConsumerId` + `ConsumerActionId`, plus the consumer `url` input when present).
- **ProjectName**: Optional project to scope the subscription to. When supplied, its id is added to the publisher inputs as `projectId`.
- **PublisherId**: The event publisher id (e.g. `tfs` for repos/boards/builds, `rm` for releases). Mandatory.
- **EventType**: The event type (e.g. `git.push`, `build.complete`, `ms.vss-pipelines.run-state-changed-event`). Mandatory.
- **ConsumerId**: The consumer id (e.g. `webHooks`). Mandatory.
- **ConsumerActionId**: The consumer action id (e.g. `httpRequest`). Mandatory.
- **ConsumerInputs**: The consumer input values (e.g. `@{ url = 'https://...' }`).
- **PublisherInputs**: The publisher input values (e.g. `@{ repository = '...'; branch = 'main' }`).
- **ResourceVersion**: The event resource version. Defaults to `1.0`.
- **Ensure**: Specifies whether the subscription should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages service hook subscriptions via the Service Hooks REST API — for example a webhook that fires an HTTP request to an external system when code is pushed.

## Examples

## Example 1: Sample Configuration using AzDoServiceHook Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoServiceHook NotifyOnPush {
            Ensure           = 'Present'
            Name             = 'notify-ci-on-push'
            ProjectName      = 'MyProject'
            PublisherId      = 'tfs'
            EventType        = 'git.push'
            ConsumerId       = 'webHooks'
            ConsumerActionId = 'httpRequest'
            ConsumerInputs   = @{ url = 'https://ci.contoso.com/hook' }
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoServiceHook
$properties = @{
    Name             = 'notify-ci-on-push'
    ProjectName      = 'MyProject'
    PublisherId      = 'tfs'
    EventType        = 'git.push'
    ConsumerId       = 'webHooks'
    ConsumerActionId = 'httpRequest'
    ConsumerInputs   = @{ url = 'https://ci.contoso.com/hook' }
}

Invoke-DscResource -Name 'AzDoServiceHook' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Notify CI on push
  type: AzureDevOpsDsc/AzDoServiceHook
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    Name: notify-ci-on-push
    ProjectName: $ProjectName
    PublisherId: tfs
    EventType: git.push
    ConsumerId: webHooks
    ConsumerActionId: httpRequest
    ConsumerInputs:
      url: https://ci.contoso.com/hook
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
