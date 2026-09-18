# DSC AzDoWorkItemQuery Resource

## Syntax

```PowerShell
AzDoWorkItemQuery [string] #ResourceName
{
    ProjectName   = [String]$ProjectName
    Path          = [String]$Path
    [ Wiql        = [String]$Wiql ]
    [ QueryType   = [String] {'flat', 'tree', 'oneHop'} ]
    [ Columns     = [String[]]$Columns ]
    [ SortColumns = [HashTable[]]$SortColumns ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **Path**: The full path of the query, including the root and any folders - for example `Shared Queries/Platform/Active Bugs`. This is the key property. Backslashes are accepted and normalized.
- **Wiql**: The WIQL statement backing the query. Required when creating a query.
- **QueryType**: `flat`, `tree` or `oneHop`. Defaults to `flat`.
- **Columns**: Field reference names to display as columns, for example `System.Id`, `System.Title`. Column order is significant and is compared as an ordered sequence.
- **SortColumns**: The sort order, as an array of hashtables: `@{ Field = 'System.Id'; Descending = $false }`.
- **Ensure**: Specifies whether the query should exist. Valid values are `Present` and `Absent`.

## Additional Information

The query's parent folder must already exist. Declare it with `AzDoQueryFolder` and chain the query to it with `DependsOn`.

**WIQL is compared in normalized form.** The Queries API does not return the WIQL it was given - it re-indents, re-wraps, re-cases keywords and appends a semicolon. Comparing the raw strings would report drift on every `Test()`, forever, even when nothing had changed. The resource normalizes both sides before comparing (collapsing whitespace, standardizing separator spacing, upper-casing keywords and dropping a trailing semicolon) while leaving field names and string literals untouched. The WIQL written back to Azure DevOps is always the statement supplied in the configuration, never the normalized form.

**Properties the configuration does not specify are not compared.** A configuration that sets only `Wiql` is stating an intent about the WIQL, not an intent that the query should have no display columns. Treating an unspecified property as "must be empty" would strip columns from every query the configuration touched.

**Changes are applied in place.** The resource uses `PATCH` rather than delete-and-recreate, because recreating a query gives it a new id, and dashboard widgets, delivery plans and ACL tokens all reference queries by id. A delete-and-recreate would leave those pointing at nothing, with no error to explain why.

A query deleted earlier is restored from the project's query recycle bin rather than failing with a name conflict, and the desired WIQL is then applied - the restored query otherwise carries whatever WIQL it had when it was deleted.

A folder occupying the query's path is reported as an error rather than resolved automatically, since removing it would delete every query beneath it.

## Examples

## Example 1: Sample Configuration using AzDoWorkItemQuery Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoQueryFolder AddPlatformFolder {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform'
        }

        AzDoWorkItemQuery AddActiveBugsQuery {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform/Active Bugs'
            Wiql        = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] = 'Bug' AND [System.State] = 'Active'"
            Columns     = @('System.Id', 'System.Title', 'System.State')
            SortColumns = @(
                @{ Field = 'System.ChangedDate'; Descending = $true }
            )
            DependsOn   = '[AzDoQueryFolder]AddPlatformFolder'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoWorkItemQuery
$properties = @{
    ProjectName = 'MyProject'
    Path        = 'Shared Queries/Platform/Active Bugs'
}

Invoke-DscResource -Name 'AzDoWorkItemQuery' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Platform Query Folder
  type: AzureDevOpsDscNative/AzDoQueryFolder
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    Path: Shared Queries/Platform
    Ensure: Present

- name: Active Bugs Query
  type: AzureDevOpsDscNative/AzDoWorkItemQuery
  dependsOn:
    - AzureDevOpsDscNative/AzDoQueryFolder/Platform Query Folder
  properties:
    ProjectName: $ProjectName
    Path: Shared Queries/Platform/Active Bugs
    Wiql: "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.State] = 'Active'"
    Columns:
      - System.Id
      - System.Title
      - System.State
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
