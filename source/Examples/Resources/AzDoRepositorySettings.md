# DSC AzDoRepositorySettings Resource

# Syntax

``` PowerShell
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

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property and cannot be changed after creation.
- __RepositoryName__: The name of the Git repository. This is a key property and cannot be changed after creation.
- __DefaultBranch__: The default branch name for the repository. Defaults to `main`.
- __AllowSquashMerge__: Whether squash merges are allowed for pull requests. Defaults to `$true`.
- __AllowRebaseMerge__: Whether rebase merges are allowed for pull requests. Defaults to `$true`.
- __AllowNoFastForward__: Whether regular (no-fast-forward) merges are allowed for pull requests. Defaults to `$true`.
- __DisableForking__: Whether forking the repository is disabled. Defaults to `$false`.
- __Ensure__: Specifies whether the settings should be applied. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages repository-level settings in Azure DevOps Git repositories, including merge strategy restrictions and forking policies. These settings enforce consistent contribution workflows across teams.

# Examples

## Example 1: Configure repository settings

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoRepositorySettings 'ConfigureRepoSettings' {
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
```

## Example 2: Allow all merge strategies

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoRepositorySettings 'AllMergeStrategies' {
            Ensure             = 'Present'
            ProjectName        = 'MyProject'
            RepositoryName     = 'MyRepository'
            DefaultBranch      = 'main'
            AllowSquashMerge   = $true
            AllowRebaseMerge   = $true
            AllowNoFastForward = $true
            DisableForking     = $false
        }
    }
}
```
