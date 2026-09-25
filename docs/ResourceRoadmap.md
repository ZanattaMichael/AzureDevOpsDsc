# AzureDevOpsDsc — Resource Roadmap

Plan of record for what is implemented and what is still outstanding, verified against
`source/Classes/` and `source/Modules/AzureDevOpsDsc.Common/` on `main` at commit
`f2ab9ca`. Sections marked **shipped** are kept as the design record for resources that
have landed; everything else is backlog.

This document supersedes and absorbs the phased list in
[#59](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/59). Where this document
disagrees with #59, it is because the proposal in #59 was checked against the code and
found to be already covered, partially covered, or mis-scoped; those cases are called out
explicitly.

---

## 1. Current coverage (verified)

83 class files exist, `001`–`134` (`117`–`118` reserved); 72 of them carry
`[DscResource()]` (the other 11 are the auth and base classes). By subsystem:

| Subsystem | Resources |
|---|---|
| Auth / base | `AuthenticationToken`, `PersonalAccessToken`, `ManagedIdentityToken`, `ServicePrincipalToken`, `CertificateToken`, `AzureCliToken`, `WorkloadIdentityFederationToken`, `DscResourceBase`, `AzDevOpsApiDscResourceBase`, `AzDevOpsDscResourceBase`, `APIRateLimit` |
| Projects / org | `AzDoProject`, `AzDoProjectServices`, `AzDoProjectPermission`, `AzDoOrganizationSettings`, `AzDoExtension`, `AzDoAuditStream`, `AzDoServiceHook`, `AzDoNotificationSubscription` |
| Identity / groups | `AzDoOrganizationGroup`, `AzDoProjectGroup`, `AzDoGroupMember`, `AzDoGroupPermission`, `AzDoUserEntitlement`, `AzDoGroupEntitlement`, `AzDoServicePrincipalEntitlement` |
| Repos | `AzDoGitRepository`, `AzDoGitPermission`, `AzDoRepositorySettings`, `AzDoBranchPolicy` |
| Boards | `AzDoAreaNodes`, `AzDoIterationNodes`, `AzDoAreaPermission`, `AzDoIterationPermission`, `AzDoWIPTags`, `AzDoWIPTagHygiene`, `AzDoProcess`, `AzDoProcessPermission` |
| Work item queries | `AzDoQueryFolder`, `AzDoWorkItemQuery`, `AzDoQueryPermission` |
| Process customization | `AzDoPicklist`, `AzDoProcessWorkItemType`, `AzDoProcessField`, `AzDoProcessState`, `AzDoProcessRule`, `AzDoProcessBehavior` |
| Teams | `AzDoTeam`, `AzDoTeamMember`, `AzDoTeamSettings` |
| Pipelines | `AzDoPipeline`, `AzDoPipelinePermission`, `AzDoPipelineSettings`, `AzDoPipelineEnvironment`, `AzDoEnvironmentApproval`, `AzDoEnvironmentPermission`, `AzDoCheckConfiguration`, `AzDoTaskGroup`, `AzDoAgentPool`, `AzDoAgentPoolPermission`, `AzDoAgentQueue`, `AzDoDeploymentGroup`, `AzDoPipelineFolder`, `AzDoPipelineFolderPermission`, `AzDoPipelineAuthorization` |
| Library / connections | `AzDoVariableGroup`, `AzDoVariableGroupPermission`, `AzDoServiceConnection`, `AzDoServiceConnectionPermission`, `AzDoSecureFile`, `AzDoSecureFilePermission` |
| Artifacts | `AzDoArtifactFeed`, `AzDoArtifactFeedPermission`, `AzDoArtifactFeedSettings`, `AzDoArtifactFeedView` |
| Classic Release Management | `AzDoReleaseFolder`, `AzDoReleaseFolderPermission`, `AzDoReleaseDefinitionPermission` |
| Wiki | `AzDoWiki` |
| Generic | `AzDoSecurityNamespacePermission` |

---

## 2. Cross-cutting prerequisite — ACL token construction

Most new *permission* resources are blocked on one shared piece of work, and it should land
before (or with) the first of them.

`New-ACLToken.ps1` builds security tokens for **12** namespaces: `Git Repositories`,
`Identity`, `CSS`, `Iteration`, `Project`, `Process`, `Build`, `Library`,
`ServiceEndpoints`, `AgentPool`, `DistributedTask`, `WorkItemQueryFolders`.
`Parse-ACLToken.ps1` mirrors that set and falls through to a `Generic` type for anything
else. `Build` now covers both the definition and the folder token form, and `Library` both
the variable group and the secure file form. `Git Repositories` now covers the branch
(`refs/heads/{encoded}`) and tag (`refs/tags/{encoded}`) token forms in addition to the
project and repository forms — see `AzDoGitPermission`'s `BranchName`/`TagName` properties
below.

`AzDoSecurityNamespacePermission` is the escape hatch — it takes a caller-supplied `Token`
string — but it gives the user no help constructing that token, which is the hard and
error-prone part. Every permission resource below needs a matching `New-ACLToken` /
`Parse-ACLToken` branch:

| New resource | Namespace | Token shape | Status |
|---|---|---|---|
| `AzDoGitPermission` (`BranchName`/`TagName`) | `Git Repositories` | `repoV2/{projectId}/{repoId}/refs/heads\|tags/{hex(UTF-16LE(segment))}` per `/`-delimited ref segment | **Shipped** — see [#76](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/76) |
| `AzDoQueryPermission` | `WorkItemQueryFolders` | `$/{projectId}/{queryFolderId}[/{childFolderId}...]` | **Shipped** |
| `AzDoSecureFilePermission` | `Library` | `Library/Project/{projectId}/SecureFile/{secureFileId}` | **Shipped** |
| `AzDoPipelineFolderPermission` | `Build` | `{projectId}/{folderPath}` | **Shipped** — see §5.4 |
| `AzDoDashboardPermission` | `Dashboards` / `DashboardsPrivileges` | `$/{projectId}/{teamId}/{dashboardId}` | Outstanding |
| `AzDoDeliveryPlanPermission` | `Plan` | `Plan/{planId}` | Outstanding |
| `AzDoTaggingPermission` | `Tagging` | `/{projectId}` | Outstanding |
| `AzDoReleaseFolderPermission` | `ReleaseManagement` | `{projectId}/{folderPath}` (folder) or `{projectId}` (root) | **Shipped** — see §5.5 |
| `AzDoReleaseDefinitionPermission` | `ReleaseManagement` | `{projectId}/{folderPath}/{definitionId}` (or `{projectId}/{definitionId}` at the root) | **Shipped** — see §5.5 |
| `AzDoAnalyticsPermission` | `Analytics` | `$/{projectId}` | Outstanding |

Whenever a namespace is added, add a `New-ACLToken` → `ConvertTo-FormattedToken` →
`Parse-ACLToken` round-trip test with it. If the build and parse directions disagree, a
permission written by `Set()` never matches the ACL read by `Get()` and the resource
reports drift forever.

**Do not hardcode permission bit values.** Read them from
`_apis/securitynamespaces/{namespaceId}` and resolve by action `name`, the way the existing
ACL helpers do. Bit layouts differ per namespace and have changed between API versions.

---

## 3. Work item queries — **shipped** (classes `101`–`103`)

Delivered as `AzDoQueryFolder`, `AzDoWorkItemQuery` and `AzDoQueryPermission`. The design
notes below are kept as the record of why the resources look the way they do; where the
implementation diverged it is called out inline.

### 3.1 `AzDoQueryFolder`

Folders are queries with `isFolder: true`; the query tree is `Shared Queries` (shareable)
and `My Queries` (per-user — out of scope for DSC, document it as unsupported).

- API: `GET|POST|PATCH|DELETE {org}/{project}/_apis/wit/queries/{path}?api-version=7.1`,
  with `$expand=all` and `$depth=N` for tree reads.
- Properties: `ProjectName` (Key), `Path` (Key, e.g. `Shared Queries/Platform/Release`),
  `Ensure`.
- Gotcha: `DELETE` on a folder deletes its whole subtree. `Remove-AzDoQueryFolder` refuses
  to delete a non-empty folder unless the guard property is set. **Divergence:** the guard
  is `AllowRecursiveDelete`, not `Force` — `GetDesiredStateParameters()` injects
  `Force = $true` into every `New`/`Set` parameter set, so a DSC property named `Force` is
  always true by the time the function sees it.
- Gotcha: deleted queries go to a recycle bin; recreating a path that is in the bin can
  return a name conflict. Handle `409` by looking in
  `_apis/wit/queries?$expand=all&$includeDeleted=true`.

### 3.2 `AzDoWorkItemQuery`

- Properties: `ProjectName` (Key), `Path` (Key, full path incl. folder), `Wiql`
  (Mandatory for flat queries), `QueryType` (`flat` | `tree` | `oneHop`),
  `Columns` (`String[]` of reference names), `SortColumns` (`Hashtable[]`:
  `@{ Field = 'System.Id'; Descending = $false }`), `Ensure`.
- Drift detection is the interesting part. WIQL comes back from the API **normalized**
  (whitespace, casing of keywords, `[Project] = @project` substitutions), so a naive
  string comparison reports permanent drift. `ConvertTo-NormalizedWiql` does this, and is
  used **only for comparison** — what gets written back is always the WIQL the
  configuration supplied.
- Prefer `PATCH` over delete-and-recreate on change: recreating changes the query GUID,
  which silently breaks any dashboard widget, delivery plan, or ACL token that references
  it.

### 3.3 `AzDoQueryPermission`

- Namespace `WorkItemQueryFolders` (id `71356614-aad7-4757-8f2c-0fb3bff6f680`).
- Token is hierarchical over **folder GUIDs**, not path names:
  `$/{projectId}/{folderId}/{subfolderId}`. So the resource must walk
  `_apis/wit/queries` resolving each path segment to its `id` before it can build a token.
  That resolution lives in a shared helper. **Divergence:** it shipped as
  `Format-AzDoQueryPath` plus the query-path resolution in the `WorkItemQueryFolders`
  branch of `New-ACLToken`, rather than as a single `Resolve-AzDoQueryPath`.
- Expected actions: `Read`, `Contribute`, `Delete`, `ManagePermissions` — confirm against
  the namespace API rather than trusting this list.
- Model it on `AzDoAreaPermission` (`CSS`), which has the closest shape: hierarchical
  token, `isInherited`, `Permissions` as `HashTable[]`.
- Performance warning: like the other hierarchical-namespace resources
  (`AzDoAreaPermission`, `AzDoIterationPermission`, `AzDoPipelinePermission`), this scans
  org-level ACLs and will take 200–400s per integration test. Budget for that.

---

## 4. Work item tag hygiene — **shipped** (class `104`)

A companion to the existing `AzDoWIPTags`, which only ensures a tag vocabulary exists. It
does nothing about the tags that accumulate *beside* that vocabulary — `Bugfix` next to
`Bug`, `frontend` next to `Frontend`, `Tech-Debt` next to `Tech Debt`.

### 4.1 Resource — `AzDoWIPTagHygiene`

| Property | Type | Notes |
|---|---|---|
| `ProjectName` | `String` | Key |
| `CanonicalTags` | `String[]` | The approved vocabulary. Keep it the same list fed to `AzDoWIPTags`. |
| `Aliases` | `Hashtable[]` | Explicit `@{ From = 'Bugfix'; To = 'Bug' }` mappings. Always applied, regardless of threshold. |
| `MatchStrategy` | `String` | `ValidateSet('Exact','Fuzzy','Both')`. `Exact` = differs only by case/whitespace/punctuation. `Fuzzy` = edit distance. Default `Exact`. |
| `SimilarityThreshold` | `Int` | 0–100, normalized Levenshtein. Only read when fuzzy matching. Default `85`. |
| `MinimumTagLength` | `Int` | Tags shorter than this are never fuzzy-matched. Default `5`. |
| `ExcludedTags` | `String[]` | Never touched. |
| `RemediationAction` | `String` | `ValidateSet('Report','Merge')`. Default `Report`. |
| `MaxAutoCorrections` | `Int` | Safety cap; exceeding it throws instead of mass-mutating. Default `25`. |

### 4.2 Mechanism

The efficient correction path is a **tag rename, not a work item edit**:

```
PATCH {org}/{project}/_apis/wit/tags/{tagIdOrName}?api-version=7.1
{ "name": "<canonical>" }
```

Renaming a tag to a name that already exists **merges** the two tags, and Azure DevOps
re-tags every work item that carried the old tag. One call per misaligned tag — no WIQL,
no work item enumeration, no batch size limits. This needs a new
`source/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Api/WIT/Update-WITTags.ps1`,
alongside the existing `List-`/`New-`/`Remove-WITTags`. That helper now exists.

Fallback, if merge-on-rename is rejected for a given tag: WIQL
`SELECT [System.Id] FROM WorkItems WHERE [System.Tags] CONTAINS '<old>'`, then a
JSON-patch on `System.Tags` per work item. Slower and non-atomic — use only as a fallback,
and log clearly when it engages.

### 4.3 DSC semantics

- `Get()` returns the misalignment set in `propertiesChanged` and sets `status` to
  `[DSCGetSummaryState]::Changed` when any tag is misaligned. (`Missing` and `Renamed` are
  also valid members of that enum and `Renamed` fits this resource well.)
- `Test()` is the report: `$false` when misalignments exist. This makes `RemediationAction
  = 'Report'` genuinely useful on its own — run it in a compliance-only configuration and
  read the reasons, with no writes at all.
- `Set()` performs merges only when `RemediationAction = 'Merge'`. Under `'Report'`,
  `Set()` writes a warning per misalignment and makes no change. That asymmetry is
  deliberate but unusual for DSC, so document it on the class.

### 4.4 Risks — design these in from the start

Tag merges are **irreversible and project-wide**. The guards matter more than the matching:

- Tags differing only in digits (`Sprint1`/`Sprint2`, `v1`/`v2`, `FY24`/`FY25`) must never
  be auto-merged. Add a hard guard that rejects any candidate pair whose difference is
  confined to digit characters, independent of `SimilarityThreshold`.
- Short tags produce false positives at any threshold — hence `MinimumTagLength`.
- Two canonical tags that are themselves similar (`Bug` / `Bugs`, if both are intentional)
  must not cause a cascade. Refuse to fuzzy-match a tag that is *already* in
  `CanonicalTags` — exact vocabulary membership always wins.
- Ship `'Report'` as the default so the first run of a new configuration can never mutate
  anything. Because `Get` returning `Error` still calls `Set` (see the enum table in
  `CLAUDE.md`), the `'Report'` refusal is repeated in `Set-AzDoWIPTagHygiene` rather than
  decided only in `Get`.
- Unit tests should cover the matcher directly (a pure function over two strings) as well
  as the resource; the matcher is where the correctness risk lives.

---

## 5. Directory / folder hierarchies

Azure DevOps exposes three folder trees that are configuration in their own right — they
carry ACLs, and objects cannot be created at a path whose folders do not exist. All three
are now manageable: query folders (§5.2), pipeline folders (§5.3–5.4) and Release folders
(§5.5), shipped as classes `101`, `107`–`108` and `132`–`133`.

### 5.1 Why folders need their own resources

A folder is not just a naming convention:

- **Ordering dependency.** `AzDoWorkItemQuery` at `Shared Queries/Platform/Release` fails
  unless `Platform/Release` exists. Without a folder resource, every query resource has to
  create its own ancestry as a side effect — which makes two resources fight over the same
  folder and makes `Test()` results depend on apply order. A distinct resource with
  `DependsOn` is the correct DSC modelling.
- **ACLs attach to folders, not just leaves.** This is how permissions are actually
  administered in both trees: grant on the folder, let definitions inherit. A module that
  can only set leaf-level ACLs cannot express the common case.
- **Deletion is recursive.** Both trees delete subtrees, so both resources need the same
  `Force` guard described in §3.1.

### 5.2 Query directories — `AzDoQueryFolder`

Covered in §3.1. Key points restated because they differ from pipeline folders:

- Folders *are* queries (`isFolder: true`), same endpoint, same `_apis/wit/queries/{path}`.
- The ACL token addresses folders by **GUID**: `$/{projectId}/{folderId}/{subfolderId}`.
  Path-to-GUID resolution is mandatory before a token can be built — hence the shared
  `Resolve-AzDoQueryPath` helper.
- Two roots: `Shared Queries` (manageable) and `My Queries` (per-user; document as
  unsupported).

### 5.3 Pipeline directories — `AzDoPipelineFolder`

- API: `GET|PUT|POST|DELETE {org}/{project}/_apis/build/folders?path={path}&api-version=7.1`.
  Distinct from the queries API — folders here are first-class objects, not definitions
  with a flag, and they carry a `description`.
- Properties: `ProjectName` (Key), `Path` (Key, e.g. `\Platform\Release` — note the
  **backslash** separator, unlike the forward slashes used by query paths), `Description`,
  `Force`, `Ensure`.
- Gotcha: paths are backslash-delimited and rooted at `\`. `Format-AzDoPipelineFolderPath`
  normalizes leading/trailing separators so `Platform\Release`, `\Platform\Release` and
  `\Platform\Release\` are one desired state rather than three — for comparison only;
  the configured path is what gets written.
- Renaming a folder is `POST .../folders?path={oldPath}` with the new path in the body; it
  moves every definition beneath it. Treat a `Path` change as a rename only when explicitly
  requested — otherwise a mistyped path silently relocates a whole tree. Safer default:
  treat `Path` as a Key, so a change is create-new + (optionally) remove-old.

### 5.4 `AzDoPipelineFolderPermission` — **shipped**, and the gap it closed

The `Build` namespace was originally wired into `New-ACLToken.ps1` for **definitions
only**: the branch resolved `ProjectId` and then a `PipelineId` from the `LivePipelines`
cache. Folder tokens have a different shape — `{projectId}/{folderPath}` with literal path
segments, not an ID — and there was no branch for them.

Both consequences are now resolved:

1. `New-ACLToken` / `ConvertTo-FormattedToken` / `Parse-ACLToken` and the `BuildPermission`
   localized regex in `AzureDevOpsDsc.Common.strings.psd1` learned the folder form
   (`BuildFolder` token type), so `AzDoPipelineFolderPermission` could be written.
2. That same work closed the gap in the **existing** `AzDoPipelinePermission`, which
   previously could not target a folder — folder-inherited pipeline permissions were
   unmanageable in shipped functionality, not only absent from the roadmap.

### 5.5 Release folders — **shipped** (classes `132`–`134`, #86)

`AzDoReleaseFolder` (`132`) / `AzDoReleaseFolderPermission` (`133`) are the third tree
(`_apis/release/folders`, `ReleaseManagement` namespace, on the `vsrm.dev.azure.com` host
rather than `dev.azure.com`). Same modelling as §5.3/5.4, and `Format-AzDoPipelineFolderPath`
is reused directly for path normalization since the rules are identical. Creation fails with
a clear error naming the org setting when classic Release Management creation is disabled,
rather than surfacing a raw 403/400.

`AzDoReleaseDefinitionPermission` (`134`) shipped alongside the folder resources rather than
waiting for `AzDoReleaseDefinition` itself: it resolves a definition by name (optionally
disambiguated by `FolderPath`) through the live `release/definitions` search endpoint, since
no resource populates the `LiveReleaseDefinitions` cache yet.

`AzDoReleaseDefinition` — the resource managing definitions themselves (stages, artifacts,
approvers) — is **outstanding**. It is a materially larger surface than the folder and
permission resources (comparable to `AzDoPipeline`) and is tracked separately; see §7.

### 5.6 Sequencing (as executed)

`AzDoQueryFolder` and `AzDoPipelineFolder` were independent of each other and shared no
code beyond conventions. Both landed **before** their permission counterparts, and
`AzDoQueryFolder` before `AzDoWorkItemQuery`. The same ordering was applied to
`AzDoReleaseFolder` → `AzDoReleaseFolderPermission` → `AzDoReleaseDefinitionPermission`.

---

## 6. Verified gaps not in #59

| Resource | Why it matters | Effort | Status |
|---|---|---|---|
| `AzDoServiceConnection` / `AzDoVariableGroup` cross-project sharing | Both objects can be shared with other projects instead of copied per project (#79). `AzDoServiceConnection` has `SharedWithProjects`/`SharedNameOverrides`, backed by the helper `Resolve-AzDoSharedProjectReferences`: the documented share endpoint for added projects and a per-project DELETE for dropped ones. ACL tokens are unaffected, since they anchor to the owning project and the connection's own id. Variable groups are not covered: Azure DevOps Services answers `"Sharing of variable group is not allowed."` to the POST, PUT and the documented `PATCH .../distributedtask/variablegroups?variableGroupId=` share call alike, so there is no route to build on. | Low | **Shipped** (service connections); variable groups blocked by the service |
| `AzDoSecureFile` / `AzDoSecureFilePermission` | Certificates, keystores and signing files used by pipelines. They share the `Library` namespace with `AzDoVariableGroup`, so most of the ACL token work already existed. | Low | **Shipped** (`105`–`106`) |
| `AzDoGroupEntitlement` | Group-based license rules. `AzDoUserEntitlement` covers only per-user licensing. | Low | **Shipped** (`109`) |
| `AzDoServicePrincipalEntitlement` | Workload identities / service principals as org members, closing the inconsistency with the existing `ServicePrincipalToken` and `WorkloadIdentityFederationToken` auth. | Low | **Shipped** (`110`) |
| `AzDoDashboard` / `AzDoDashboardWidget` / `AzDoDashboardPermission` | Team and project dashboards. `Dashboards` namespace needs adding. | Medium | Outstanding |
| `AzDoDeliveryPlan` | Cross-team roadmap plans; `Plan` namespace. | Medium | Outstanding |
| `AzDoElasticPool` | VMSS-backed agent pools — increasingly the default for self-hosted compute. Complements the existing `AzDoAgentPool`. | Medium | Outstanding |
| `AzDoBuildRetentionSettings` | Project-level run/artifact retention (`_apis/build/retention`). | Low | Outstanding |
| `AzDoBoardColumn` / `AzDoBoardSettings` / `AzDoCardRule` | Board columns, swimlanes, card fields and styling. `AzDoTeamSettings` covers backlog/iteration/area defaults and working days, but not the board itself. | Medium | Outstanding |
| `AzDoWikiPage` | `AzDoWiki` manages the wiki, not its pages or their ordering. | Medium | Outstanding |
| `AzDoCheckConfiguration` — `queue`/`variablegroup`/`securefile` resource types | Checks were previously limited to `environment`, `repository` and `endpoint`; agent queues, variable groups and secure files can carry checks too (e.g. Branch control on a signing certificate). | Low | **Shipped** (#77) |

### Process customization — mostly closed

`AzDoProcess` exposes only `ProcessName`, `ParentProcessName`, `Description`. Six of the
seven pieces that make an inherited process useful now have resources of their own:

| Piece | Resource | Status |
|---|---|---|
| Custom and inherited WITs | `AzDoProcessWorkItemType` | **Shipped** (`112`) |
| Field definitions and per-WIT assignment | `AzDoProcessField` | **Shipped** (`113`) |
| Custom workflow states | `AzDoProcessState` | **Shipped** (`114`) |
| Conditional rules | `AzDoProcessRule` | **Shipped** (`115`) |
| Backlog behaviors | `AzDoProcessBehavior` | **Shipped** (`116`) |
| Shared picklists | `AzDoPicklist` | **Shipped** (`111`) |
| Form pages, groups, controls | `AzDoProcessLayout` | Outstanding |

Two constraints the shipped five share, worth carrying into `AzDoProcessLayout`:

- **Only inherited processes can be customized.** The system processes (Agile, Scrum,
  Basic, CMMI) are read-only. `Resolve-AzDoProcessWorkItemType` enforces this, and reads
  the `work/processes` view to do it — the `LiveProcesses` cache is built from the classic
  `_apis/process/processes` endpoint, which returns neither `customizationType` nor
  `parentProcessTypeId`.
- **Compare normalized, store what the user wrote.** Rule conditions come back from the
  API as objects with omitted keys filled in as nulls, so raw comparison reports drift on
  every `Test()`. `ConvertTo-NormalizedRuleClause` exists for comparison only.

`#59` collapsed this whole area into two bullets (`AzDoCustomField` / `AzDoWorkItemType`)
under Phase 4, which understated it considerably.

---

## 7. Reconciliation with #59

Items from #59 checked against the code:

| #59 item | Finding |
|---|---|
| `AzDoOrgPipelineSettings`, `...JobAuthorizationScope`, `...ArtifactsRetention` | **Partially covered.** `AzDoPipelineSettings` already exposes `EnforceJobAuthScope`, `EnforceJobAuthScopeForReleases`, `EnforceReferencedRepoScopedToken`, `EnforceSettableVar`, `PublishPipelineMetadata`, `StatusBadgesArePrivate`, `DisableClassicPipelineCreation`, `DisableImpliedYAMLCiTrigger` — but scoped to `ProjectName`. The gap is the **org-scoped** equivalent, not the settings themselves. **Blocked (#83): there is no organization-scoped REST route.** The public reference documents General Settings only with a `{project}` segment, and the same route without one does not exist — against the live test organization, `GET https://dev.azure.com/{org}/_apis/build/generalsettings` returns 404 `The controller for path '/_apis/build/generalsettings' was not found or does not implement IController`. A first attempt at `AzDoOrgPipelineSettings` built on that route was withdrawn for this reason. The switches are visible in the portal (Organization settings → Pipelines → Settings), so a route exists somewhere, but not a documented one. Before building anything, spike what the portal calls and decide whether an undocumented contract is acceptable. The same spike should check whether the project-scoped GET shows that a switch is locked on by the organization: today `AzDoPipelineSettings` cannot tell, so a project that wants such a switch off reports drift. |
| `AzDoOrganizationPolicy` | **Closed (#84).** Implemented as five more properties on `AzDoOrganizationSettings` rather than a new resource: `EnableIPConditionalAccessPolicyValidation`, `LogAuditEvents`, `AllowTeamAdminsToInviteUsers`, `EnableRequestAccess` (+ `RequestAccessUrl`) and `EnableArtifactsFeedUpstreamProtection`, written through `PATCH _apis/OrganizationPolicy/Policies/{policyName}` and read from the policy page's data provider, or per policy from the same route's GET (which needs `defaultValue`) when the page routes return nothing, separate from the original five properties' `_apis/settings/entries/host` mechanism. The policy properties are tri-state strings (`''` = unmanaged). `LimitUserVisibility` was left out — it verified as a preview-feature flag, not a confirmed organization policy. Microsoft Entra tenant-level policies (PAT restrictions, organization-creation restrictions) are out of scope here and tracked in #85. |
| `AzDoRepositoryDefaultBranch`, `AzDoForkPolicy` | **Already covered** by `AzDoRepositorySettings` (`DefaultBranch`, `DisableForking`, `AllowSquashMerge`, `AllowRebaseMerge`, `AllowNoFastForward`). Drop both. |
| `AzDoCommitStatusPolicy`, `AzDoPullRequestPolicySettings` | **Closed (#74).** `AzDoBranchPolicy` now detects `PolicySettings` drift and supports several policies of the same `PolicyType` in one scope via `PolicyIdentifier`, so a commit status policy is `PolicyType = 'StatusCheck'` with `PolicyIdentifier` set to the status name, and pull request policy settings (merge strategy, comment requirements, work item linking) are `PolicySettings` on the existing policy types. No new resource needed. Deferred: `PolicyIdentifier` only matches a top-level scalar or array settings value, not one nested a level deeper (e.g. a status check's `genre`/`name` pair) — see `Test-AzDoBranchPolicyIdentifierMatch`. |
| `AzDoTeamFieldValues` | **Likely covered** by `AzDoTeamSettings` (`DefaultAreaPath`, `AreaPaths`). Verify, then drop. |
| `AzDoWorkItemQuery`, `AzDoQueryFolderPermission` | **Closed.** Split into `AzDoQueryFolder` / `AzDoWorkItemQuery` / `AzDoQueryPermission` and shipped (§3). |
| `AzDoPipelineRetentionPolicy` | Confirmed gap; listed above as `AzDoBuildRetentionSettings`. |
| `AzDoResourceAuthorization` | **Closed.** Shipped as `AzDoPipelineAuthorization` (class `119`, [#78](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/78)) — manages the `pipelinePermissions` REST API (which pipelines may *use* a service connection, agent queue, variable group, secure file, environment or repository), distinct from `AzDoCheckConfiguration` (approval/other checks gating a run) and the per-resource permission resources (who may *administer* the resource). |
| `AzDoGroupEntitlement` | **Closed.** Shipped as class `109` (§6). |
| `AzDoPipelineFolder` | **Closed.** Shipped as classes `107`–`108`, together with the `Build` folder ACL token (§5.3–5.4). |
| `AzDoDeploymentGroupAgent` | **Closed for tags/removal.** Shipped as `AzDoEnvironmentKubernetesResource` (`125`), `AzDoEnvironmentVMResource` (`126`) and `AzDoDeploymentGroupTarget` (`127`) — see §8. VM and deployment-group targets are agent-install-only by design; DSC never registers one, only manages tags and removal of an already-registered target. Kubernetes resources are fully creatable via the REST API. |
| `AzDoWikiPage`, `AzDoElasticPool`, dashboards, delivery plans, analytics | Confirmed gaps, still outstanding. |
| Classic Release Management (Phase 2 in #59) | **Partially closed** (#86). `AzDoReleaseFolder`, `AzDoReleaseFolderPermission` and `AzDoReleaseDefinitionPermission` shipped as classes `132`–`134`, together with `ReleaseManagement` ACL token support (§2). `AzDoReleaseDefinition` itself — the resource managing a definition's stages, artifacts and approvers — remains outstanding; it is a materially larger surface, comparable in size to `AzDoPipeline`. |
| Test Management (Phase 3 in #59) | Confirmed gap. Genuinely unrepresented, but demand is narrower than queries/dashboards; keep after the §6 gaps. |
| `AzDoBillingSettings`, `AzDoPatPolicy`, `AzDoExtensionPolicy`, `AzDoAuditLogAlert` | **Spiked in [#85](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/85), see [`docs/Spikes/TenantScopedPolicies.md`](Spikes/TenantScopedPolicies.md).** All four verdicts are **unsupported / not built**: `AzDoPatPolicy` and an org-creation-restriction candidate have no documented REST route and the tenant-level halves need a Microsoft Entra tenant-admin identity this module cannot model; `AzDoBillingSettings` is excluded outright because every write is a billing/purchase change; `AzDoExtensionPolicy` has no documented route for the policy toggles (role constraint alone would pass); `AzDoAuditLogAlert` is not a distinct feature and folds into the shipped `AzDoAuditStream` (#69). The org-level "restrict PAT creation" allow-list is a follow-up property for `AzDoOrganizationSettings` once #84 lands, not a tenant policy. |

---

## 8. Status

Merged to `main` in [#62](https://github.com/ZanattaMichael/AzureDevOpsDsc/pull/62) —
16 new resources, classes `101`–`116`:

| Resource | Notes |
|---|---|
| `AzDoQueryFolder`, `AzDoWorkItemQuery`, `AzDoQueryPermission` | §3. Includes WIQL normalization and `WorkItemQueryFolders` ACL token support. |
| `AzDoWIPTagHygiene` | §4. Report-only by default. |
| `AzDoSecureFile`, `AzDoSecureFilePermission` | §6. Includes the `SecureFile` form of the `Library` ACL token. |
| `AzDoPipelineFolder`, `AzDoPipelineFolderPermission` | §5.3–5.4. Includes the `Build` folder ACL token, which also closed the shipped `AzDoPipelinePermission` gap recorded in §5.4. |
| `AzDoGroupEntitlement`, `AzDoServicePrincipalEntitlement` | §6. |
| `AzDoPicklist`, `AzDoProcessWorkItemType`, `AzDoProcessField`, `AzDoProcessState`, `AzDoProcessRule`, `AzDoProcessBehavior` | §6 process customization. The "system processes are read-only" rule lives in `Resolve-AzDoProcessWorkItemType`. |

This closed §3, §4, §5.2, §5.3, §5.4 and most of §6, and added `WorkItemQueryFolders`,
the `SecureFile` form of `Library` and the folder form of `Build` to the ACL token helpers
(§2).

Added in [#82](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/82) — 3 new
resources, classes `125`–`127`:

| Resource | Notes |
|---|---|
| `AzDoEnvironmentKubernetesResource` | Environment Kubernetes namespace resource, addressed via a service connection. Fully creatable/removable through the REST API. The issue's `ResourceName` property is exposed as `KubernetesResourceName` (reserved elsewhere in the module). The Kubernetes provider API has no Update call, so any drift (including Tags-only drift) is resolved by delete-then-recreate, which changes the resource's id — Tags drift is never silently ignored. |
| `AzDoEnvironmentVMResource` | Tags and removal of an already-registered environment VM resource. Registration is agent-install-only (`config.cmd`/`config.sh`); this resource never creates one. `Present` with no agent registered under `MachineName` makes `Get` report `Error`/`AgentNotRegistered` and `Set` **throw** (not `Write-Error`) with an install-the-agent message, since an `Error` status still routes to `Set`. `Absent` with nothing registered is the desired state. |
| `AzDoDeploymentGroupTarget` | Tags and removal of an already-registered deployment group target. Same agent-install-only, throw-on-`Set` design as `AzDoEnvironmentVMResource`, for deployment groups instead of pipeline environments. |

Live-organization integration coverage: `AzDoEnvironmentKubernetesResource.tests.ps1` creates a
synthetic Kubernetes-type service connection with a placeholder kubeconfig and exercises
create/no-drift/tag-drift-and-fix/remove; if the organization's `providers/kubernetes` endpoint
validates cluster reachability before accepting the resource, the affected assertions report via
`Set-ItResult -Skipped` (never `-Skip`) rather than being silently omitted, and unit tests
(`tests/Unit/.../AzDoEnvironmentKubernetesResource/`) cover the lookup/drift/remediation logic
independently of that. `AzDoEnvironmentVMResource.tests.ps1` and
`AzDoDeploymentGroupTarget.tests.ps1` can only exercise the unregistered-machine paths in CI
(`Present` → `Test` false, `Set` throws; `Absent` → `Test` true) because installing an agent is
outside what a CI job can do; the tag-patch path is unit-tested only.

Still outstanding, in the order below:

- **`AzDoProcessLayout`** (§6) — the one remaining piece of process customization, and a
  sub-project of its own: the layout API is a three-level tree with its own ordering and
  inheritance rules, which does not fit the flat compare-and-patch shape the other six
  share.
- **Dashboards, delivery plans and board configuration** (§6) — `AzDoDashboard`,
  `AzDoDashboardWidget`, `AzDoDashboardPermission`, `AzDoDeliveryPlan`, `AzDoBoardColumn`,
  `AzDoBoardSettings`, `AzDoCardRule`. The `Dashboards` and `Plan` ACL namespaces are
  still unimplemented (§2).
- **Remaining §6 gaps** — `AzDoElasticPool`, `AzDoBuildRetentionSettings`, `AzDoWikiPage`.
- **Org-scoped pipeline settings** (§7) — **blocked**: there is no organization-scoped
  `_apis/build/generalsettings` route (it returns 404). Needs a spike of the route the portal
  uses before any resource is built (#83).
- **Test management** (§7).
- **`AzDoReleaseDefinition`** (§5.5, §7) — the remaining piece of classic release
  management; `AzDoReleaseFolder`, `AzDoReleaseFolderPermission` and
  `AzDoReleaseDefinitionPermission` shipped in #86.
- **Tenant-scoped items** (§7) — **spiked and closed as unsupported/not-built**, see
  [`docs/Spikes/TenantScopedPolicies.md`](Spikes/TenantScopedPolicies.md) (#85). No
  resources were built; class prefixes `130`–`131` reserved for the spike are unused.

---

## 8a. DSC v3 export (#92)

DSC v3's PowerShell adapter can call a parameterless static `Export()` on a class-based
resource to generate its configuration from live state instead of it being hand-written.
See USAGE.md, "Onboarding an Existing Organization with Export", for how it is dispatched
and how to run it.

**Shipped** — first increment ([#92](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/92)):

| Resource | Notes |
|---|---|
| `AzDoProject` | Exports `Ensure`, `ProjectName`, `ProjectDescription`, `Visibility`. Skips projects that are not `wellFormed`. |
| `AzDoGitRepository` | Exports `Ensure`, `ProjectName`, `RepositoryName`. Skips disabled repositories. |

Both reuse the shared `AzDevOpsDscResourceBase::ExportDscResourceInstances()` plumbing and the
`Protect-AzDoExportedSecretProperty` secret-redaction helper; neither resource has secret
properties today.

Still outstanding — every other resource has no `Export-<ResourceName>` function yet, so
calling `Export()` on it throws `"export is not implemented for <ResourceName>"`. Adding one
is additive per resource (no shared-plumbing changes needed) and should follow the existing
`Get-`/list-cache pattern each resource already has. Not yet attempted:

- Permission resources (`AzDoAreaPermission`, `AzDoIterationPermission`, `AzDoPipelinePermission`,
  `AzDoProjectPermission`, `AzDoQueryPermission`, `AzDoSecureFilePermission`,
  `AzDoPipelineFolderPermission`) — exporting an ACL means walking every relevant token and
  reverse-parsing it with `Parse-ACLToken`, which is more work per resource than a plain list.
- The work item query, tag hygiene, secure file, pipeline folder, entitlement and inherited
  process resources (classes `101`–`116`).
- A `dsc resource export` CLI-level integration test (`tests/Integration/V3/`) — deferred:
  `dsc resource export`'s output shape (a DSC configuration document, distinct from the single
  JSON object `get`/`set`/`test` return) needs to be confirmed against the runner's actual `dsc`
  version before `V3TestHelpers.ps1`'s `Invoke-DscV3Resource` is extended to parse it.

---

## 8b. `AzDoPipeline` — GitHub/Bitbucket repositories and pipeline variables (issue #81) — **shipped**

`AzDoPipeline` (class `068`) gained three properties rather than a new class, since the
existing resource already owned the pipeline/build-definition object these extend:

- **`RepositoryType`** (`TfsGit` default, `GitHub`, `GitHubEnterprise`, `Bitbucket`). The
  classic Build Definitions API (what this resource reads, compares and updates) and the
  Pipelines create API disagree on the string for each type
  (`TfsGit`/`GitHub`/`GitHubEnterprise`/`Bitbucket` vs.
  `azureReposGit`/`gitHub`/`gitHubEnterprise`/`bitbucket`); `Convert-AzDoPipelineRepositoryType`
  translates for the create call only. `TfsGit` addresses the repository by `id`/`name`; the
  other three address it by `owner/repo` (as both `id` and `name` on the build definition)
  plus a service connection `id`, and `Get-AzDoPipelineRepositoryUrl` supplies the clone URL
  the definition records.
- **`ServiceConnectionName`**, resolved to a connection id by the new helper
  `Resolve-AzDoServiceConnection` (cache-first, live-fallback — the same pattern
  `AzDoServiceConnection` itself uses). Mandatory only when `RepositoryType` is not `TfsGit`;
  `New`/`Set` guard on this explicitly, because an `Error` status from `Get` still reaches
  `Set` (see `CLAUDE.md`'s "Error still calls Set" gotcha) and the refusal has to be repeated
  there.
- **`Variables`** (`Hashtable[]`, shaped `@{ Name; Value; IsSecret; AllowOverride }`), written
  through the new private API function `Set-DevOpsPipelineVariables`. Pipeline variables live
  on the classic build definition's `variables` map, not on the Pipelines resource, and a
  `PUT` has to send the whole definition back — so this reads the definition, replaces only
  the named variables in its map, and writes it back untouched otherwise. Only the variables
  listed in the configuration are managed; pre-existing variables not named there are left
  alone.

**Updates go through the build definition.** The Pipelines API (`_apis/pipelines`) creates
and lists pipelines but has no update verb — a `PATCH` or `PUT` to `_apis/pipelines/{id}` is
refused with `405`. `Set-DevOpsPipeline` therefore reads the pipeline's build definition,
changes the managed fields (name, folder, YAML path, default branch, and the repository only
when its type, name or service connection differs) and writes the whole definition back with a
`PUT`. The create call takes no default branch either, so `New-AzDoPipeline` follows the create
with the same update.

**Secret variables are write-only.** Azure DevOps never returns a secret variable's value in
any API response, so `Get-AzDoPipeline` cannot compare one and must not report drift based on
a value it can never see: drift detection for a secret variable is limited to its presence and
its `IsSecret`/`AllowOverride` flags. `New`/`Set` always write the value the configuration
currently holds, on every call, whether or not it actually changed on the far end — there is no
way from this side to tell.

**Live coverage gap.** The CI organization has no GitHub or Bitbucket service connection
configured, so `GitHub`, `GitHubEnterprise` and `Bitbucket` — and the
`Resolve-AzDoServiceConnection` resolution path they exercise — are covered by unit tests only
(`tests/Unit/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Helper/Resolve-AzDoServiceConnection.tests.ps1`,
`Convert-AzDoPipelineRepositoryType.tests.ps1`, `Get-AzDoPipelineRepositoryUrl.tests.ps1`,
`Set-DevOpsPipeline.tests.ps1`, and the `AzDoPipeline` Get/New/Set unit tests).
The integration suite exercises `Variables` (create, update, secret rotation, no-drift `Test`)
only against a `TfsGit` pipeline, in
`tests/Integration/Resources/AzDoPipeline.Variables.tests.ps1`. Adding a GitHub/Bitbucket
service connection to the live test organization would close this gap; nothing in the code
depends on staying that way.

## 9. Suggested order of work

Steps 1–6 of the original plan (`WorkItemQueryFolders` ACL support, the three query
resources, `AzDoWIPTagHygiene`, secure files, pipeline folders and the two entitlement
resources) are done, as is all of process customization except the layout API. What
remains:

1. **`AzDoProcessLayout`** (§6) — finishes the process customization sub-project.
2. **`AzDoElasticPool`**, **`AzDoBuildRetentionSettings`** (§6) — low effort each, no ACL
   dependency.
3. **Dashboards and delivery plans** (§6) — `Dashboards` and `Plan` ACL namespaces first
   (§2), then `AzDoDashboard` → `AzDoDashboardWidget` → `AzDoDashboardPermission`, and
   `AzDoDeliveryPlan`.
4. **Board configuration** (§6) — `AzDoBoardColumn`, `AzDoBoardSettings`, `AzDoCardRule`.
5. **`AzDoWikiPage`** (§6).
6. **Org-scoped pipeline settings** (§7) — blocked on a spike; no documented org-scoped route.
7. Test management, then **`AzDoReleaseDefinition`** (§5.5) — the remaining piece of
   classic release management now that its folders and permissions (#86) have shipped.
8. **Tenant-scoped items** (§7) — done: spiked in #85 and closed as unsupported/not-built,
   see [`docs/Spikes/TenantScopedPolicies.md`](Spikes/TenantScopedPolicies.md).

Per-resource checklist (from `CLAUDE.md`): class in `source/Classes/` with the next numeric
prefix (continue from `117`), public functions under
`Resources/Functions/Public/<ResourceName>/` named `Get-`/`New-`/`Set-`/`Remove-` (the base
class resolves them by that convention, so a missing one fails at apply time), exactly one
`[DscProperty(Key)]`, no DSC property named `Force`, unit tests mirroring the public
function path, an integration test using the `New-RestAuthHeader` pattern, and a rebuild +
redeploy before running integration tests.

---

## 10. Cross-cutting — Azure DevOps Server support

Whether this module targets on-premise Azure DevOps Server in addition to Azure DevOps
Services is tracked as its own cross-cutting effort in
[#91](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/91), not as a per-resource
item here. See [`docs/AzureDevOpsServerSupport.md`](AzureDevOpsServerSupport.md) for the
increment plan; the decision of whether to build it out is the repository owner's and is
recorded there as pending.

---

## 11. Team administration and backlog visibility (#80) — **shipped**

Two properties added to existing Teams resources rather than new classes, since both are
facets of objects those resources already own:

- **`AzDoTeamMember.IsTeamAdmin`** (`Boolean`, optional, default `$false`) — grants or
  revokes the "Manage membership" bit on the team's own token (`{ProjectId}\{TeamId}`) in
  the `Identity` security namespace. The bit is never hardcoded: `Get-DevOpsTeamAdministrator`
  and `Set-DevOpsTeamAdministrator` both resolve it from the `Identity` namespace's
  `actions` (the `SecurityNamespaces` cache) by name each time, so a namespace revision
  cannot silently target the wrong permission. Because an `accesscontrollists` write with
  `merge=false` replaces the *entire* ACL for the submitted token, `Set-DevOpsTeamAdministrator`
  reads the team's whole live ACL first and rewrites only the target member's ACE, carrying
  every other identity's entry through unchanged; an ACE that becomes zero-permission after a
  revoke is removed entirely rather than left as an empty entry. `Remove-AzDoTeamMember`
  always attempts the revoke on removal, regardless of the `IsTeamAdmin` value supplied, so a
  removed member cannot retain admin rights it no longer appears to hold in the team's own
  membership UI; a failure to revoke is logged as a warning and does not block the membership
  removal itself.
- **`AzDoTeamSettings.BacklogVisibilities`** (`Hashtable`, optional) — a map of backlog
  category reference name (for example `Microsoft.EpicCategory`, `Microsoft.FeatureCategory`,
  `Microsoft.RequirementCategory`) to a boolean, applied through
  `PATCH .../_apis/work/teamsettings`'s `backlogVisibilities` dictionary. Drift is reported
  only for the categories the configuration states, per the "only compare what the
  configuration states" convention (§`CLAUDE.md`) — a category the live team has hidden but
  the configuration never mentions is left alone, and a category absent from the live
  dictionary is treated as hidden (`$false`) by default when the configuration states it
  should be visible.

**Deferred**: accepting a backlog *behavior* name (as shown in the Backlogs configuration
page in the Azure DevOps UI, e.g. "Epics", "Features", "Stories/Requirements") as an
alternative to the category reference name it maps to. There is no reliable mapping table in
this codebase or in the classic `_apis/process/processes` cache between a process's backlog
behavior names and the fixed `Microsoft.*Category` reference names `backlogVisibilities`
actually keys on — the mapping is process-specific for inherited processes with renamed or
added backlog levels, and building it correctly would need the same `work/processes` view
that `Resolve-AzDoProcessWorkItemType` already reads for a different reason (§6). Configurations
target `BacklogVisibilities` by category reference name for now.
