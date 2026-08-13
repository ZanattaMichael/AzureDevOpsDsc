# Welcome to the AzureDevOpsDsc wiki

The **AzureDevOpsDsc** module provides class-based DSC resources for managing
Azure DevOps organizations, projects, repositories, permissions, pipelines, and
more — all through the Azure DevOps REST API.

- [Issues and feature requests](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues)
- [Changelog](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CHANGELOG.md)
- [Contributing](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CONTRIBUTING.md)

---

## Getting started

Install from the PowerShell Gallery:

```powershell
Install-Module -Name AzureDevOpsDsc -Repository PSGallery
```

Verify installation:

```powershell
Get-DscResource -Module AzureDevOpsDsc
```

See the [Quick-Start](Quick-Start) guide for a full walkthrough including
authentication setup and your first DSC configuration.

---

## Guides

| Guide | Description |
|---|---|
| [Quick-Start](Quick-Start) | Install, authenticate, and run your first DSC configuration |
| [Authentication](Authentication) | All six authentication methods — PAT, Managed Identity, Service Principal, Certificate, Azure CLI, Workload Identity Federation |
| [Development](Development) | Load from source, run unit tests, contribute |
| [CI-CD](CI-CD) | GitHub Actions workflows, required secrets and variables |

---

## DSC resource documentation

### Projects, organization, groups and teams

| Resource | Description |
|---|---|
| [AzDoProject](Resources/AzDoProject) | Creates and manages Azure DevOps projects |
| [AzDoProjectServices](Resources/AzDoProjectServices) | Enables or disables services within a project |
| [AzDoOrganizationSettings](Resources/AzDoOrganizationSettings) | Manages organization-level settings |
| [AzDoProjectGroup](Resources/AzDoProjectGroup) | Creates and manages groups within a project |
| [AzDoOrganizationGroup](Resources/AzDoOrganizationGroup) | Creates and manages organization-level groups |
| [AzDoGroupMember](Resources/AzDoGroupMember) | Manages membership of users, groups, and service principals |
| [AzDoTeam](Resources/AzDoTeam) | Creates and manages teams within a project |
| [AzDoTeamMember](Resources/AzDoTeamMember) | Manages team membership |
| [AzDoTeamSettings](Resources/AzDoTeamSettings) | Configures a team's iteration/area paths, working days, and bug behaviour |
| [AzDoUserEntitlement](Resources/AzDoUserEntitlement) | Adds/removes organization users and manages their access level |

### Repositories and policies

| Resource | Description |
|---|---|
| [AzDoGitRepository](Resources/AzDoGitRepository) | Creates and manages Git repositories |
| [AzDoRepositorySettings](Resources/AzDoRepositorySettings) | Manages Git repository settings |
| [AzDoBranchPolicy](Resources/AzDoBranchPolicy) | Manages branch policies |

### Permissions

| Resource | Description |
|---|---|
| [AzDoProjectPermission](Resources/AzDoProjectPermission) | Manages project-level permissions |
| [AzDoGitPermission](Resources/AzDoGitPermission) | Manages Git repository permissions |
| [AzDoAreaPermission](Resources/AzDoAreaPermission) | Manages area path permissions |
| [AzDoIterationPermission](Resources/AzDoIterationPermission) | Manages iteration path permissions |
| [AzDoAgentPoolPermission](Resources/AzDoAgentPoolPermission) | Manages agent pool permissions |
| [AzDoEnvironmentPermission](Resources/AzDoEnvironmentPermission) | Manages pipeline environment permissions |
| [AzDoPipelinePermission](Resources/AzDoPipelinePermission) | Manages build/pipeline permissions |
| [AzDoServiceConnectionPermission](Resources/AzDoServiceConnectionPermission) | Manages service connection permissions |
| [AzDoVariableGroupPermission](Resources/AzDoVariableGroupPermission) | Manages variable group permissions |
| [AzDoArtifactFeedPermission](Resources/AzDoArtifactFeedPermission) | Manages artifact feed permissions |
| [AzDoSecurityNamespacePermission](Resources/AzDoSecurityNamespacePermission) | Manages permissions for an arbitrary security namespace |
| [AzDoProcessPermission](Resources/AzDoProcessPermission) | Manages Process security namespace permissions |
| [AzDoGroupPermission](Resources/AzDoGroupPermission) | *(Not currently supported)* Manages group-level identity permissions |

### Pipelines, environments and agents

| Resource | Description |
|---|---|
| [AzDoPipeline](Resources/AzDoPipeline) | Creates and manages YAML pipeline definitions |
| [AzDoPipelineEnvironment](Resources/AzDoPipelineEnvironment) | Creates and manages pipeline environments |
| [AzDoEnvironmentApproval](Resources/AzDoEnvironmentApproval) | Manages approval checks on a pipeline environment |
| [AzDoCheckConfiguration](Resources/AzDoCheckConfiguration) | Manages pipeline checks on a protected resource |
| [AzDoDeploymentGroup](Resources/AzDoDeploymentGroup) | Creates and manages deployment groups |
| [AzDoAgentPool](Resources/AzDoAgentPool) | Creates and manages organization agent pools |
| [AzDoAgentQueue](Resources/AzDoAgentQueue) | Creates and manages project agent queues |
| [AzDoTaskGroup](Resources/AzDoTaskGroup) | Creates and manages task groups |
| [AzDoVariableGroup](Resources/AzDoVariableGroup) | Creates and manages variable groups |
| [AzDoServiceConnection](Resources/AzDoServiceConnection) | Creates and manages service connections |
| [AzDoPipelineSettings](Resources/AzDoPipelineSettings) | Manages a project's pipeline general settings |

### Boards and work items

| Resource | Description |
|---|---|
| [AzDoAreaNodes](Resources/AzDoAreaNodes) | Manages area path classification nodes |
| [AzDoIterationNodes](Resources/AzDoIterationNodes) | Manages iteration path classification nodes |
| [AzDoWIPTags](Resources/AzDoWIPTags) | Manages work item tags |
| [AzDoProcess](Resources/AzDoProcess) | Creates and manages inherited processes |
| [AzDoNotificationSubscription](Resources/AzDoNotificationSubscription) | Manages notification subscriptions |

### Artifacts, wiki, extensions and auditing

| Resource | Description |
|---|---|
| [AzDoArtifactFeed](Resources/AzDoArtifactFeed) | Creates and manages artifact feeds |
| [AzDoArtifactFeedSettings](Resources/AzDoArtifactFeedSettings) | Configures feed upstream sources and retention |
| [AzDoArtifactFeedView](Resources/AzDoArtifactFeedView) | Creates and manages feed views |
| [AzDoWiki](Resources/AzDoWiki) | Creates and manages project and code wikis |
| [AzDoExtension](Resources/AzDoExtension) | Installs and uninstalls organization extensions |
| [AzDoAuditStream](Resources/AzDoAuditStream) | Manages audit log streaming |
| [AzDoServiceHook](Resources/AzDoServiceHook) | Creates and manages service hook subscriptions |

---

## Prerequisites

- PowerShell **7.0** or higher
- Windows (DSC engine requires Windows for `Invoke-DscResource`)
- An Azure DevOps organization with appropriate permissions
- Authentication credentials — see the [Authentication](Authentication) guide
