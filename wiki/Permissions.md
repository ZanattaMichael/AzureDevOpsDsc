# Permissions & ACLs

This page is the single starting point for everything related to Azure DevOps permissions, ACLs, and security namespaces in **AzureDevOpsDscNative**. If you're trying to figure out "how do I grant a group access to X", start here.

> Content on this page is verified against the module's own generated resource documentation in [`source/Examples/Resources/`](https://github.com/zanattamichael/AzureDevOpsDsc/tree/main/source/Examples/Resources) of the source repository — the same content the module ships as comment-based help. If you find a mismatch between this page and the module you're running, the module's `Get-Help <ResourceName>` output (or the `source/Examples/Resources/<ResourceName>.md` file for your installed version) wins.

## How Azure DevOps permissions work in this module

Azure DevOps stores authorization as **Access Control Lists (ACLs)** inside **CSS Security Namespaces** — one namespace per kind of object (Git repos, Area Paths, Iteration Paths, Build pipelines, Environments, Service Connections, Agent Pools, Variable Groups, Artifact Feeds, Processes, Identities/Groups, and the Project itself). Each ACL is attached to a **token** (a path-like string identifying the object, e.g. a repository ID or an area path GUID chain) and contains one or more **Access Control Entries (ACEs)** — one per identity (user or group) — each of which sets **Allow**/**Deny** bits for named permissions (also called "actions" or "bits") defined by that namespace.

Every permission resource takes a `Permissions` **array**, where each entry has an `Identity` string and a `Permission` hashtable of bit-name → `Allow`/`Deny`. Multiple identities can be set in a single resource block. Two variants exist:

- **Path-scoped resources** (`AzDoAreaPermission`, `AzDoIterationPermission`, `AzDoGitPermission`) key only on a project + path, so a single resource block commonly manages ACEs for several different identities at once.
- **Object + group-scoped resources** (everything else below — pipelines, the project itself, environments, service connections, agent pools, variable groups, processes, security namespaces directly, and group/identity permissions) key on the target object **plus** a mandatory `GroupName` property, and conventionally carry a single `Permissions` array entry whose `Identity` matches that `GroupName` — one resource block per identity being granted access.

In both variants:
- `isInherited` (where present) controls whether the ACL inherits from its parent scope. Set to `$false` to break inheritance and enforce only the explicit entries you define.
- `Ensure = 'Present'` (default) applies the entries; `'Absent'` removes them.
- Either the permission bit's **Name** (e.g. `GENERIC_WRITE`) or its **DisplayName** (e.g. `'Edit this node'`) can usually be used as the hashtable key — **use `Name`**, it's stable across Azure DevOps UI/locale changes and is what's shown below.

```powershell
# General shape — path-scoped, multiple identities
AzDoAreaPermission {
    ProjectName = 'MyProject'
    AreaPath    = '\MyProject\Sub Area'
    isInherited = $false
    Permissions = @(
        @{
            Identity   = '[MyProject]\My Team'
            Permission = @{ WORK_ITEM_READ = 'Allow'; GENERIC_WRITE = 'Allow' }
        }
    )
}

# General shape — object-scoped, single identity
AzDoPipelinePermission {
    ProjectName  = 'MyProject'
    PipelineName = 'MyBuildPipeline'
    GroupName    = '[MyProject]\Contributors'
    Permissions  = @{ ViewBuilds = 'Allow'; QueueBuilds = 'Allow' }
}
```

## Resource reference

| Resource | Scope | Identity model | Notes |
|---|---|---|---|
| [AzDoAreaPermission](Resources/AzDoAreaPermission.md) | Area Path (CSS namespace) | Multi-identity array | Full org-wide ACL scan; 200-400s per test run — see below |
| [AzDoIterationPermission](Resources/AzDoIterationPermission.md) | Iteration Path (CSS namespace) | Multi-identity array | Full org-wide ACL scan; 200-400s per test run — see below |
| [AzDoGitPermission](Resources/AzDoGitPermission.md) | Git repository | Multi-identity array | |
| [AzDoPipelinePermission](Resources/AzDoPipelinePermission.md) | Build pipeline definition | Single identity + `GroupName` | Full org-wide ACL scan; 200-400s per test run — see below |
| [AzDoProjectPermission](Resources/AzDoProjectPermission.md) | Project (`$PROJECT` namespace) | Single identity + `GroupName` | |
| [AzDoEnvironmentPermission](Resources/AzDoEnvironmentPermission.md) | Pipeline environment | Single identity + `GroupName` | |
| [AzDoServiceConnectionPermission](Resources/AzDoServiceConnectionPermission.md) | Service connection / endpoint | Single identity + `GroupName` | |
| [AzDoAgentPoolPermission](Resources/AzDoAgentPoolPermission.md) | Agent pool | Single identity + `GroupName` | |
| [AzDoVariableGroupPermission](Resources/AzDoVariableGroupPermission.md) | Variable group ("library item") | Single identity + `GroupName` | |
| [AzDoArtifactFeedPermission](Resources/AzDoArtifactFeedPermission.md) | Artifact feed | Role-based (`Reader`/`Collaborator`/`Contributor`/`Administrator`), not bit-based | Different model — see its resource page |
| [AzDoProcessPermission](Resources/AzDoProcessPermission.md) | Process (`$PROCESS` namespace) | Single identity + `ProcessName` as key | Use `ProcessName = 'AllProcesses'` for the org-wide root scope |
| [AzDoGroupPermission](Resources/AzDoGroupPermission.md) | Identity/group object itself | Single identity + `GroupName` as key | Controls who can read/edit/delete the *group*, not what the group can do elsewhere |
| [AzDoSecurityNamespacePermission](Resources/AzDoSecurityNamespacePermission.md) | Any raw CSS Security Namespace + token | Single identity + `GroupName` | Generic escape hatch when no dedicated resource exists for a namespace |

## Permission bit reference by resource

Names below are what you put as hashtable keys in `Permissions`. `[allow, deny]` means either value is valid for that bit.

### AzDoAreaPermission / AzDoIterationPermission

| Name | DisplayName |
|---|---|
| `GENERIC_READ` | View this node |
| `GENERIC_WRITE` | Edit this node |
| `CREATE_CHILDREN` | Create child nodes |
| `DELETE` | Delete this node |
| `WORK_ITEM_READ` | View work items in this node |
| `WORK_ITEM_WRITE` | Edit work items in this node |
| `MANAGE_TEST_PLANS` | Manage test plans |
| `MANAGE_TEST_SUITES` | Manage test suites |
| `WORK_ITEM_SAVE_COMMENT` | Edit work item comments in this node (Area only) |

### AzDoGitPermission

| Name | DisplayName |
|---|---|
| `Administer` | Administer (not recommended) |
| `GenericRead` | Read |
| `GenericContribute` | Contribute |
| `ForcePush` | Force push (rewrite history, delete branches and tags) |
| `CreateBranch` | Create branch |
| `CreateTag` | Create tag |
| `ManageNote` | Manage notes |
| `PolicyExempt` | Bypass policies when pushing |
| `CreateRepository` | Create repository |
| `DeleteRepository` | Delete or disable repository |
| `RenameRepository` | Rename repository |
| `EditPolicies` | Edit policies |
| `RemoveOthersLocks` | Remove others' locks |
| `ManagePermissions` | Manage permissions |
| `PullRequestContribute` | Contribute to pull requests |
| `PullRequestBypassPolicy` | Bypass policies when completing pull requests |
| `ViewAdvSecAlerts` | Advanced Security: view alerts |
| `DismissAdvSecAlerts` | Advanced Security: manage and dismiss alerts |
| `ManageAdvSecScanning` | Advanced Security: manage settings |

### AzDoPipelinePermission

| Name | DisplayName |
|---|---|
| `ViewBuilds` | View builds |
| `EditBuildQuality` | Edit build quality |
| `RetainIndefinitely` | Retain indefinitely |
| `DeleteBuilds` | Delete builds |
| `ManageBuildQualities` | Manage build qualities |
| `DestroyBuilds` | Destroy builds |
| `UpdateBuildInformation` | Update build information |
| `QueueBuilds` | Queue builds |
| `ManageBuildQueue` | Manage build queue |
| `StopBuilds` | Stop builds |
| `ViewBuildDefinition` | View build pipeline |
| `EditBuildDefinition` | Edit build pipeline |
| `DeleteBuildDefinition` | Delete build pipeline |
| `OverrideBuildCheckInValidation` | Override check-in validation by build |
| `AdministerBuildPermissions` | Administer build permissions (not recommended) |

### AzDoProjectPermission

| Name | DisplayName |
|---|---|
| `GENERIC_READ` | View project-level information |
| `GENERIC_WRITE` | Edit project-level information |
| `DELETE` | Delete team project (not recommended) |
| `PUBLISH_TEST_RESULTS` | Publish test results |
| `ADMINISTER_BUILD` | Administer a build |
| `START_BUILD` | Start a build |
| `EDIT_BUILD_STATUS` | Edit build quality |
| `UPDATE_BUILD` | Write to build operational store |
| `DELETE_TEST_RESULTS` | Delete test runs |
| `VIEW_TEST_RUNS` | View test runs |
| `MANAGE_TEST_ENVIRONMENTS` | Manage test environments |
| `MANAGE_TEST_CONFIGURATIONS` | Manage test configurations |
| `WORK_ITEM_DELETE` | Delete and restore work items |
| `WORK_ITEM_MOVE` | Move work items out of this project |
| `WORK_ITEM_PERMANENTLY_DELETE` | Permanently delete work items |
| `RENAME` | Rename team project |
| `MANAGE_PROPERTIES` | Manage project properties |
| `MANAGE_SYSTEM_PROPERTIES` | Manage system project properties |
| `BYPASS_RULES` | Bypass rules on work item updates |
| `SUPPRESS_NOTIFICATIONS` | Suppress notifications for work item updates |

### AzDoEnvironmentPermission

| Name | DisplayName |
|---|---|
| `View` | View environment |
| `Manage` | Manage environment |
| `Use` | Use environment in pipelines |
| `Administer` | Administer environment (not recommended) |

### AzDoServiceConnectionPermission

| Name | DisplayName |
|---|---|
| `Use` | Use service connection |
| `Administer` | Administer service connection (not recommended) |
| `Create` | Create service connection |
| `ViewAuthorization` | View authorization |
| `ViewEndpoint` | View service connection |

### AzDoAgentPoolPermission

| Name | DisplayName |
|---|---|
| `Use` | Use |
| `Manage` | Manage (not recommended) |
| `Create` | Create |
| `ViewAuthorization` | View Authorization |
| `ManagePermissions` | Manage Permissions (not recommended) |

### AzDoVariableGroupPermission

| Name | DisplayName |
|---|---|
| `View` | View library item |
| `Administer` | Administer library item (not recommended) |
| `Create` | Create library item |
| `ViewSecrets` | View library item secrets |
| `Use` | Use library item |
| `Owner` | Owner library item (not recommended) |

### AzDoArtifactFeedPermission (role-based, not bit-based)

| Role | Description |
|---|---|
| `Reader` | Can list and download packages |
| `Collaborator` | Can list, download, and save packages from upstream sources |
| `Contributor` | Can push, list, and download packages |
| `Administrator` | Full control including managing feed settings and permissions (not recommended) |

### AzDoProcessPermission

| Name | DisplayName |
|---|---|
| `Create` | Create process (allows creating inherited/child processes) |
| `Edit` | Edit process |
| `Delete` | Delete process |
| `AdministerProcessPermissions` | Administer process permissions |
| `ReadProcessPermissions` | Read process permissions |

### AzDoGroupPermission

| Name | DisplayName |
|---|---|
| `Read` | View identity information |
| `Write` | Edit identity information |
| `Delete` | Delete identity information |
| `ManageMembership` | Manage group membership |
| `CreateScope` | Create identity scopes |
| `RestoreScope` | Restore identity scopes |

### AzDoSecurityNamespacePermission

Generic resource — the permission bit names depend entirely on which `SecurityNamespace` you target (e.g. `'Build'`, `'Git Repositories'`, `'Project'`). See [its resource page](Resources/AzDoSecurityNamespacePermission.md) for worked examples against multiple namespaces. Prefer a dedicated resource (above) when one exists for your object type; use this one when it doesn't.

## Identity syntax

Identities are specified as strings in the form:

```
[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, or GroupDisplayName
```

Examples:
- `'[MyProject]\My Team'` — a team/group scoped to a project
- `'[MyOrganization]\Project Collection Administrators'` — an org-level group
- `'[MyProject]\user@example.com'` — a specific user

## Common pitfalls

- **CSS Security Namespace scans are slow.** `AzDoAreaPermission`, `AzDoIterationPermission`, and `AzDoPipelinePermission` (and any custom use of `AzDoSecurityNamespacePermission` against those namespaces) enumerate **all** ACLs in the namespace across the organization to resolve tokens. Expect **200-400 seconds** per `Test()`/`Get()` call against these resources — this is normal, not a hang. Plan integration test timeouts and pipeline stage timeouts accordingly.
- **Bit name vs display name.** Both usually work as hashtable keys, but `Name` (the constant, e.g. `GENERIC_WRITE`) is stable; `DisplayName` (e.g. `'Edit this node'`) can change with Azure DevOps UI updates/localization. Prefer `Name`.
- **`isInherited = $false` is destructive to existing inherited ACEs** on that path/object — it breaks inheritance, meaning only what you explicitly declare in `Permissions` will apply going forward. Don't set this casually on shared/parent scopes.
- **`AzDoArtifactFeedPermission` doesn't use Allow/Deny bits** — it assigns a single role name per identity. Don't try to pass a bits hashtable to it.
- **`AzDoProcessPermission` uses the sentinel `ProcessName = 'AllProcesses'`** to target the organization-wide root process scope (`$PROCESS`). Anything else scopes to that one specific inherited process.

## See also

- [LCM Configuration](LCMConfiguration.md) — how to apply permission resources (and everything else) at scale via `Dsc.PipelineRunner`
- [Authentication](Authentication.md) — the identity your DSC run applies these ACLs *as* needs sufficient rights itself (typically Project Collection Administrator or equivalent namespace-level Administer permission)
- [Best Practices](BestPractices.md#security-best-practices) — permission management patterns
