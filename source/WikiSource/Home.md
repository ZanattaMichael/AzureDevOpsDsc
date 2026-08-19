# Welcome to the AzureDevOpsDscNative wiki

<sup>*AzureDevOpsDscNative v#.#.#*</sup>

Here you will find all the information you need to make use of the AzureDevOpsDscNative
DSC resources in the latest release. This includes details of the resources that are
available, current capabilities, known issues, and information to help plan a DSC based
implementation of AzureDevOpsDscNative.

Please leave comments, feature requests, and bug reports for this module in the
[issues section](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues) for this repository.

> **Note:** This is a native DSC v3 module where every resource is discoverable and invokable
> by `dsc.exe` via the `Microsoft.Adapter/PowerShell` adapter, using generated adapted resource
> manifests. No wrapper resources required.

## About AzureDevOpsDscNative

**AzureDevOpsDscNative** is a comprehensive DSC module that enables you to:

- **Manage Projects**: Create and configure Azure DevOps projects with specific settings
- **Control Permissions**: Define fine-grained permissions for users and groups across resources
- **Manage Teams**: Create and manage teams and team membership
- **Configure Repositories**: Manage Git repositories, permissions, and settings
- **Setup Pipelines**: Configure pipelines, environments, and pipeline settings
- **Manage Service Connections**: Create and manage service connections for CI/CD
- **Configure Variable Groups**: Create and manage variable groups
- **Manage Artifacts**: Configure artifact feeds and permissions
- **Setup Infrastructure**: Manage agent pools, deployment groups, and other infrastructure
- **Apply Policies**: Configure branch policies and other governance settings

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the following command:

```powershell
Install-Module -Name AzureDevOpsDscNative -Repository PSGallery
```

- Download AzureDevOpsDscNative from the [PowerShell Gallery](https://www.powershellgallery.com/packages/AzureDevOpsDscNative)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

To confirm installation, run the below command and ensure you see the AzureDevOpsDscNative
DSC resources available:

```powershell
Get-DscResource -Module AzureDevOpsDscNative
```

### Prerequisites

The minimum requirement for this module is PowerShell 7.0.

- **PowerShell 7.0 or later** — Required for this module
- **Azure DevOps Account** — Access to an Azure DevOps organisation
- **Authentication** — Personal Access Token (PAT), Managed Identity, Service Principal, or
  other supported authentication methods (see [Authentication Guide](Authentication.md))

### Basic Usage Example

```powershell
# Set up authentication
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -PersonalAccessToken 'my-pat'

# Apply a DSC configuration
Configuration AzureDevOpsConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoProject 'MyProject' {
            Ensure             = 'Present'
            ProjectName        = 'MySampleProject'
            ProjectDescription = 'This is a sample Azure DevOps project.'
            SourceControlType  = 'Git'
            ProcessTemplate    = 'Agile'
            Visibility         = 'Private'
        }
    }
}

AzureDevOpsConfig
Start-DscConfiguration -Path ./AzureDevOpsConfig -Wait -Verbose
```

## Documentation

### [Authentication Guide](Authentication.md)

How to configure authentication using `New-AzDoAuthenticationProvider`:

- Personal Access Tokens (PAT)
- Managed Identity
- Service Principal (client secret or certificate)
- Azure CLI Token
- Workload Identity Federation

### [LCM Configuration](LCMConfiguration.md)

How to apply configurations at scale using the companion
**[AZDO-DSC-LCM](https://github.com/ZanattaMichael/AzDO-DSC-LCM)** project: Datum-based
configuration layering, LCM Rules, `dependsOn`/`condition`/`postExecutionScript`, and
running `Invoke-AZDoLCM`.

### [Permissions & ACLs](Permissions.md)

The single reference for permissions and ACLs — CSS Security Namespaces, ACL/ACE concepts,
full permission bit reference, identity syntax, and common pitfalls.

### [Best Practices](BestPractices.md)

Guidelines and recommendations for using AzureDevOpsDscNative effectively:

- Configuration management patterns
- Security best practices
- Performance optimisation
- Error handling and troubleshooting
- Large-scale deployments with AZDO-DSC-LCM

### [Examples](Examples.md)

Practical examples and scenarios covering project setup, security, CI/CD pipelines, artifact
feeds, and team structure automation.

### [FAQ](FAQ.md)

Frequently asked questions.

### [Troubleshooting](Troubleshooting.md)

Common issues and how to resolve them.

## DSC Resource Documentation

### Resources with detailed documentation

* [AzDoGitPermission](Resources/AzDoGitPermission.md)
* [AzDoGitRepository](Resources/AzDoGitRepository.md)
* [AzDoGroupMember](Resources/AzDoGroupMember.md)
* [AzDoGroupPermission](Resources/AzDoGroupPermission.md)
* [AzDoOrganizationGroup](Resources/AzDoOrganizationGroup.md)
* [AzDoProject](Resources/AzDoProject.md)
* [AzDoProjectGroup](Resources/AzDoProjectGroup.md)
* [AzDoProjectServices](Resources/AzDoProjectServices.md)

### All available resources

AzureDevOpsDscNative includes **49 DSC resources** covering:

**Organisation & Groups**

- `AzDoOrganizationGroup` — Manage organisation-level groups
- `AzDoGroupMember` — Manage group membership
- `AzDoGroupPermission` — Manage group permissions
- `AzDoOrganizationSettings` — Configure organisation settings
- `AzDoUserEntitlement` — Manage user entitlements

**Projects**

- `AzDoProject` — Create and manage projects
- `AzDoProjectGroup` — Manage project groups
- `AzDoProjectServices` — Manage project services
- `AzDoProjectPermission` — Manage project permissions

**Teams**

- `AzDoTeam` — Create and manage teams
- `AzDoTeamMember` — Manage team membership
- `AzDoTeamSettings` — Configure team settings

**Repository & Git**

- `AzDoGitRepository` — Create and manage Git repositories
- `AzDoGitPermission` — Manage repository permissions
- `AzDoRepositorySettings` — Configure repository settings
- `AzDoAreaNodes` — Manage area nodes
- `AzDoIterationNodes` — Manage iteration nodes

**Permissions & Security**

- `AzDoAreaPermission` — Manage area permissions
- `AzDoIterationPermission` — Manage iteration permissions
- `AzDoSecurityNamespacePermission` — Manage security namespace permissions
- `AzDoBranchPolicy` — Configure branch policies

**Pipelines & CI/CD**

- `AzDoPipeline` — Create and manage pipelines
- `AzDoPipelinePermission` — Manage pipeline permissions
- `AzDoPipelineEnvironment` — Manage pipeline environments
- `AzDoEnvironmentPermission` — Manage environment permissions
- `AzDoEnvironmentApproval` — Configure environment approvals
- `AzDoPipelineSettings` — Configure pipeline settings
- `AzDoCheckConfiguration` — Manage pipeline checks

**Service Connections & Variables**

- `AzDoServiceConnection` — Create and manage service connections
- `AzDoServiceConnectionPermission` — Manage service connection permissions
- `AzDoVariableGroup` — Create and manage variable groups
- `AzDoVariableGroupPermission` — Manage variable group permissions

**Agents & Infrastructure**

- `AzDoAgentPool` — Create and manage agent pools
- `AzDoAgentPoolPermission` — Manage agent pool permissions
- `AzDoAgentQueue` — Manage agent queues
- `AzDoDeploymentGroup` — Create and manage deployment groups

**Artifacts**

- `AzDoArtifactFeed` — Create and manage artifact feeds
- `AzDoArtifactFeedPermission` — Manage feed permissions
- `AzDoArtifactFeedSettings` — Configure feed settings
- `AzDoArtifactFeedView` — Manage feed views

**Other Resources**

- `AzDoWiki` — Manage project wikis
- `AzDoTaskGroup` — Create and manage task groups
- `AzDoExtension` — Manage extensions
- `AzDoAuditStream` — Configure audit streams
- `AzDoNotificationSubscription` — Manage notification subscriptions
- `AzDoServiceHook` — Create and manage service hooks
- `AzDoProcess` — Create and manage custom processes
- `AzDoProcessPermission` — Manage process permissions
- `AzDoWIPTags` — Manage WIP tags

## Change log

A full list of changes in each version can be found in the
[change log](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CHANGELOG.md).
