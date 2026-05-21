# DSC AzDoRepositorySettings Resource

## Syntax

```PowerShell
AzDoRepositorySettings [string] #ResourceName
{
    ProjectName          = [String]$ProjectName
    RepositoryName       = [String]$RepositoryName
    [ DefaultBranch      = [String]$DefaultBranch ]
    [ AllowSquashMerge   = [Boolean]$AllowSquashMerge ]
    [ AllowRebaseMerge   = [Boolean]$AllowRebaseMerge ]
    [ AllowNoFastForward = [Boolean]$AllowNoFastForward ]
    [ DisableForking     = [Boolean]$DisableForking ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource. It cannot be changed after creation.
- **RepositoryName**: The name of the Git repository. This is a key property. It cannot be changed after creation.
- **DefaultBranch**: The default branch name for the repository. Defaults to `main`.
- **AllowSquashMerge**: Whether squash merges are allowed for pull requests. Defaults to `$true`.
- **AllowRebaseMerge**: Whether rebase merges are allowed for pull requests. Defaults to `$true`.
- **AllowNoFastForward**: Whether regular (no-fast-forward) merges are allowed for pull requests. Defaults to `$true`.
- **DisableForking**: Whether forking the repository is disabled. Defaults to `$false`.
- **Ensure**: Specifies whether the settings should be applied. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages repository-level settings in Azure DevOps Git repositories, including merge strategy restrictions and forking policies. These settings enforce consistent contribution workflows across teams.

## Examples

## Example 1: Sample Configuration using AzDoRepositorySettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoRepositorySettings ConfigureRepoSettings {
            Ensure             = 'Present'
            ProjectName        = 'MyProject'
            RepositoryName     = 'MyRepository'
            DefaultBranch      = 'main'
            AllowSquashMerge   = $true
            AllowRebaseMerge   = $false
            AllowNoFastForward = $false
            DisableForking     = $true
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoRepositorySettings
$properties = @{
    ProjectName    = 'MyProject'
    RepositoryName = 'MyRepository'
}

Invoke-DscResource -Name 'AzDoRepositorySettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: Repository Merge Settings
  type: AzureDevOpsDsc/AzDoRepositorySettings
  dependsOn:
    - AzureDevOpsDsc/AzDoGitRepository/MyRepository
  properties:
    ProjectName: $ProjectName
    RepositoryName: $RepositoryName
    DefaultBranch: main
    AllowSquashMerge: true
    AllowRebaseMerge: false
    AllowNoFastForward: false
    DisableForking: true
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
