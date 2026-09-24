# DSC AzDoWikiPage Resource

## Syntax

```PowerShell
AzDoWikiPage [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    WikiName               = [String]$WikiName
    Path                   = [String]$Path
    [ Content              = [String]$Content ]
    [ ContentPath          = [String]$ContentPath ]
    [ Order                = [Int32]$Order ]
    [ AllowRecursiveDelete = [Boolean]$AllowRecursiveDelete ]
    [ Ensure                = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project.
- **WikiName**: The name of the wiki that contains this page, resolved the same way `AzDoWiki`
  resolves it. Only a project wiki (`WikiType 'projectWiki'`) is supported - a code wiki is
  refused with a clear error, since its content lives in a Git branch rather than in the wiki
  page store.
- **Path**: The full path of the wiki page, for example `/Runbooks/On-call`. This is the resource
  key.
- **Content**: The page's Markdown content. Mutually exclusive with `ContentPath`. Comparison
  ignores line-ending and trailing-whitespace-only differences; what is written back is always
  exactly what the configuration supplied.
- **ContentPath**: A local file to read the page's Markdown content from, read on the node
  applying the configuration. Mutually exclusive with `Content`. A path that does not exist is
  refused.
- **Order**: The page's desired position among its sibling pages. Left unspecified, the page's
  order is never compared or changed.
- **AllowRecursiveDelete**: Deleting a wiki page deletes every sub-page beneath it. Removal of a
  page that still has sub-pages is refused unless this is set to `$true`.
- **Ensure**: Specifies whether the wiki page should exist. Valid values are `Present` and
  `Absent`.

## Additional Information

This resource manages the content and sibling ordering of a single page inside an existing
project wiki. `AzDoWiki` manages the wiki itself, not its pages.

Updates send the page's current ETag back as `If-Match`, so a page changed out of band since the
last `Get` is caught as a conflict (412) rather than silently overwritten by a stale write.

## Examples

## Example 1: Sample Configuration using AzDoWikiPage Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoWikiPage AddRunbookPage {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            WikiName    = 'MyProjectWiki'
            Path        = '/Runbooks/On-call'
            Content     = "# On-call`n`nCall the on-call engineer."
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoWikiPage
$properties = @{
    ProjectName = 'MyProject'
    WikiName    = 'MyProjectWiki'
    Path        = '/Runbooks/On-call'
}

Invoke-DscResource -Name 'AzDoWikiPage' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: On-call Runbook Page
  type: AzureDevOpsDscNative/AzDoWikiPage
  dependsOn:
    - AzureDevOpsDscNative/AzDoWiki/MyProjectWiki
  properties:
    ProjectName: $ProjectName
    WikiName: MyProjectWiki
    Path: /Runbooks/On-call
    ContentPath: C:\Docs\OnCallRunbook.md
    Order: 0
    Ensure: Present
```

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
