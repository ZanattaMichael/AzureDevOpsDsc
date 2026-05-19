# DSC AzDoWiki Resource

# Syntax

``` PowerShell
AzDoWiki [string] #ResourceName
{
    ProjectName        = [String]$ProjectName
    WikiName           = [String]$WikiName
    [ WikiType         = [String] {'projectWiki', 'codeWiki'} ]
    [ RepositoryName   = [String]$RepositoryName ]
    [ MappedPath       = [String]$MappedPath ]
    [ Version          = [String]$Version ]
    [ Ensure           = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __WikiName__: The name of the wiki. This is a key property.
- __WikiType__: The type of wiki. Valid values are `projectWiki` (a built-in project wiki) and `codeWiki` (a wiki sourced from a Git repository). Defaults to `projectWiki`.
- __RepositoryName__: For `codeWiki` type, the name of the repository that contains the wiki content. Optional.
- __MappedPath__: For `codeWiki` type, the folder path within the repository that contains the wiki content. Defaults to `/`.
- __Version__: For `codeWiki` type, the branch or commit to use. Optional.
- __Ensure__: Specifies whether the wiki should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages wikis in Azure DevOps projects. Project wikis are automatically created within the project, while code wikis are sourced from content stored in a Git repository.

# Examples

## Example 1: Create a project wiki

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoWiki 'AddProjectWiki' {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            WikiName    = 'MyProjectWiki'
            WikiType    = 'projectWiki'
        }
    }
}
```

## Example 2: Create a code wiki from a repository

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoWiki 'AddCodeWiki' {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            WikiName       = 'MyCodeWiki'
            WikiType       = 'codeWiki'
            RepositoryName = 'MyRepository'
            MappedPath     = '/docs'
            Version        = 'main'
        }
    }
}
```

## Example 3: Remove a wiki

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoWiki 'RemoveWiki' {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            WikiName    = 'MyProjectWiki'
        }
    }
}
```
