# Quick Start

This guide takes you from zero to your first Azure DevOps DSC configuration in a
few minutes.

---

## 1. Prerequisites

- **PowerShell 7.0+** (required by the module)
- **Windows** (DSC engine is Windows-only)
- An **Azure DevOps organization** and credentials — see [Authentication](Authentication)

---

## 2. Install the module

```powershell
Install-Module -Name AzureDevOpsDsc -Repository PSGallery -Scope CurrentUser
```

Verify the install:

```powershell
Get-DscResource -Module AzureDevOpsDsc
```

---

## 3. Set the cache directory

The module uses a file-based cache to store live state. Set the environment variable
before using the module — add it to your PowerShell profile to make it permanent:

```powershell
$env:AZDODSC_CACHE_DIRECTORY = "$env:LOCALAPPDATA\AzureDevOpsDscCache"
New-Item -Path $env:AZDODSC_CACHE_DIRECTORY -ItemType Directory -Force | Out-Null
```

---

## 4. Authenticate

Call `New-AzDoAuthenticationProvider` once per session (or once per DSC
configuration run). It persists credentials to `ModuleSettings.clixml` so
DSC resources can restore them automatically.

**Personal Access Token** (simplest for getting started):

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'myorg' -PersonalAccessToken '<pat>'
```

For production use see the full [Authentication](Authentication) guide (Managed
Identity, Service Principal, Azure CLI, etc.).

---

## 5. Create your first project — using `Invoke-DscResource`

`Invoke-DscResource` is the quickest way to apply a single resource without
writing a full DSC configuration:

```powershell
# Check current state (Get)
Invoke-DscResource -Name AzDoProject -Method Get -ModuleName AzureDevOpsDsc -Property @{
    ProjectName = 'MyFirstProject'
}

# Ensure the project exists (Set)
Invoke-DscResource -Name AzDoProject -Method Set -ModuleName AzureDevOpsDsc -Property @{
    ProjectName       = 'MyFirstProject'
    Ensure            = 'Present'
    SourceControlType = 'Git'
    ProcessTemplate   = 'Agile'
    Visibility        = 'Private'
}

# Verify (Test)
Invoke-DscResource -Name AzDoProject -Method Test -ModuleName AzureDevOpsDsc -Property @{
    ProjectName = 'MyFirstProject'
    Ensure      = 'Present'
}
```

---

## 6. Full DSC configuration

Use a `Configuration` block to manage multiple resources declaratively:

```powershell
Configuration MyAzureDevOpsBaseline {

    Import-DscResource -ModuleName AzureDevOpsDsc

    Node localhost {

        AzDoProject WebPortal {
            Ensure            = 'Present'
            ProjectName       = 'WebPortal'
            SourceControlType = 'Git'
            ProcessTemplate   = 'Agile'
            Visibility        = 'Private'
        }

        AzDoProjectServices WebPortalServices {
            DependsOn      = '[AzDoProject]WebPortal'
            ProjectName    = 'WebPortal'
            Repositories   = 'enabled'
            Pipelines      = 'enabled'
            Boards         = 'enabled'
            TestPlans      = 'disabled'
            Artifacts      = 'enabled'
        }

        AzDoProjectGroup Reviewers {
            DependsOn        = '[AzDoProject]WebPortal'
            ProjectName      = 'WebPortal'
            GroupName        = 'Code Reviewers'
            GroupDescription = 'Team members who review pull requests'
        }
    }
}

# Compile the configuration to a MOF
MyAzureDevOpsBaseline -OutputPath .\MyConfig

# Apply
Start-DscConfiguration -Path .\MyConfig -Wait -Verbose -Force
```

---

## 7. Using the AzDO-DSC-LCM (YAML-based)

The companion [AzDO-DSC-LCM](https://github.com/ZanattaMichael/AzDO-DSC-LCM)
project lets you manage resources with YAML playbooks (similar to Ansible):

```yaml
# AllNodes/WebPortal/Project.yml
variables:
  ProjectName: WebPortal
  ProjectDescription: 'Internal web portal'

resources:
  - name: Project
    type: AzureDevOpsDsc/AzDoProject
    properties:
      projectName: $ProjectName
      projectDescription: $ProjectDescription
      visibility: private
      SourceControlType: Git
      ProcessTemplate: Agile
```

```powershell
Invoke-AzDoLCM `
    -AzureDevopsOrganizationName 'myorg' `
    -ConfigurationDirectory      'C:\Datum\DSCOutput\' `
    -AuthenticationType          'ManagedIdentity' `
    -Mode                        'Set'
```

---

## Next steps

- Browse all resources on the [Home](Home) page
- Read the full [Authentication](Authentication) guide for production auth methods
- Learn how to run unit and integration tests on the [Development](Development) page
