# DSC AzDoWIPTagHygiene Resource

## Syntax

```PowerShell
AzDoWIPTagHygiene [string] #ResourceName
{
    ProjectName           = [String]$ProjectName
    CanonicalTags         = [String[]]$CanonicalTags
    [ Aliases             = [HashTable[]]$Aliases ]
    [ MatchStrategy       = [String] {'Exact', 'Fuzzy', 'Both'} ]
    [ SimilarityThreshold = [Int32]$SimilarityThreshold ]
    [ MinimumTagLength    = [Int32]$MinimumTagLength ]
    [ ExcludedTags        = [String[]]$ExcludedTags ]
    [ RemediationAction   = [String] {'Report', 'Merge'} ]
    [ MaxAutoCorrections  = [Int32]$MaxAutoCorrections ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This is the key property.
- **CanonicalTags**: The approved tag vocabulary. Usually the same list given to `AzDoWIPTags`.
- **Aliases**: Explicit mappings applied regardless of threshold: `@( @{ From = 'Bugfix'; To = 'Bug' } )`.
- **MatchStrategy**: `Exact` (differs only in case, whitespace or punctuation), `Fuzzy` (edit distance) or `Both`. Defaults to `Exact`.
- **SimilarityThreshold**: 0–100, the minimum normalized similarity for a fuzzy match. Defaults to `85`.
- **MinimumTagLength**: Tags shorter than this are never fuzzy-matched. Defaults to `5`.
- **ExcludedTags**: Tags that are never touched.
- **RemediationAction**: `Report` (the default) detects and reports without changing anything; `Merge` applies the corrections.
- **MaxAutoCorrections**: Safety cap. If more misalignments are found than this, nothing is merged and the resource reports an error. Defaults to `25`.

## Additional Information

`AzDoWIPTags` ensures a tag vocabulary exists. This resource deals with the tags that accumulate *beside* it — `Bugfix` next to `Bug`, `frontend` next to `Frontend`, `Tech-Debt` next to `Tech Debt`.

### How a correction is applied

By renaming the misaligned tag to its canonical name. Renaming a tag to a name that already exists makes Azure DevOps **merge** the two and re-tag every affected work item, so a correction costs one API call per tag rather than one per work item — no WIQL, no work item enumeration, no batch limits.

### Report first

A tag merge is **irreversible and project-wide**. The resource therefore defaults to `RemediationAction = 'Report'`: `Test()` returns `$false` when misalignments exist, and `Set()` writes a warning per misalignment without changing anything. That makes it usable as a compliance check on its own, and means the first run of a new configuration can never silently rewrite a project's tags.

That asymmetry — a `Set()` that deliberately does not set — is unusual for a DSC resource and is intentional.

### Matching rules and guards

Matching runs in order of confidence: explicit `Aliases` always apply; `Exact` covers case, whitespace and punctuation differences; `Fuzzy` uses normalized edit distance and is gated by `SimilarityThreshold` and `MinimumTagLength`.

Because a wrong merge cannot be undone, several guards are absolute:

- **Tags differing only in digits are never merged.** `Sprint1`/`Sprint2`, `v1`/`v2`, `FY24`/`FY25` are separate concepts that fuzzy matching would otherwise collapse. This guard ignores the threshold entirely.
- **A tag already in the vocabulary is never touched.** Exact membership always wins, so two intentionally similar canonical tags (`Bug` and `Bugs`) cannot cascade into each other.
- **Short tags are never fuzzy-matched**, since short strings are close to everything.
- **A tag matching two canonical tags equally well is left alone** rather than merged on a coin flip.
- **`MaxAutoCorrections`** stops a misconfigured vocabulary from rewriting a whole project. The cap is evaluated during `Get`, so a breach surfaces at `Test()` time rather than at apply time.

Corrections are addressed by tag id rather than by name, because a chain of merges removes names as it goes and a later rename addressed by name would fail once its target had been merged away.

## Examples

## Example 1: Reporting misaligned tags

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoWIPTagHygiene ReportTagHygiene {
            ProjectName       = 'MyProject'
            CanonicalTags     = @('Bug', 'Tech Debt', 'Frontend')
            RemediationAction = 'Report'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoWIPTagHygiene
$properties = @{
    ProjectName   = 'MyProject'
    CanonicalTags = @('Bug', 'Tech Debt', 'Frontend')
}

Invoke-DscResource -Name 'AzDoWIPTagHygiene' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Tag Hygiene
  type: AzureDevOpsDscNative/AzDoWIPTagHygiene
  dependsOn:
    - AzureDevOpsDscNative/AzDoWIPTags/Vocabulary
  properties:
    ProjectName: $ProjectName
    CanonicalTags:
      - Bug
      - Tech Debt
      - Frontend
    Aliases:
      - From: Bugfix
        To: Bug
    RemediationAction: Merge
    MaxAutoCorrections: 10
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
