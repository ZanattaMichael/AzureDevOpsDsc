# AzureDevOpsDsc — Resource Roadmap

Consolidated backlog of DSC resources still to be added to the module, verified against
`source/Classes/` and `source/Modules/AzureDevOpsDsc.Common/` at the time of writing.

This document supersedes and absorbs the phased list in
[#59](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/59). Where this document
disagrees with #59, it is because the proposal in #59 was checked against the code and
found to be already covered, partially covered, or mis-scoped; those cases are called out
explicitly.

---

## 1. Current coverage (verified)

61 resource classes exist, `001`–`100`. By subsystem:

| Subsystem | Resources |
|---|---|
| Auth / base | `AuthenticationToken`, `PersonalAccessToken`, `ManagedIdentityToken`, `ServicePrincipalToken`, `CertificateToken`, `AzureCliToken`, `WorkloadIdentityFederationToken`, `DscResourceBase`, `AzDevOpsApiDscResourceBase`, `AzDevOpsDscResourceBase`, `APIRateLimit` |
| Projects / org | `AzDoProject`, `AzDoProjectServices`, `AzDoProjectPermission`, `AzDoOrganizationSettings`, `AzDoExtension`, `AzDoAuditStream`, `AzDoServiceHook`, `AzDoNotificationSubscription` |
| Identity / groups | `AzDoOrganizationGroup`, `AzDoProjectGroup`, `AzDoGroupMember`, `AzDoGroupPermission`, `AzDoUserEntitlement` |
| Repos | `AzDoGitRepository`, `AzDoGitPermission`, `AzDoRepositorySettings`, `AzDoBranchPolicy` |
| Boards | `AzDoAreaNodes`, `AzDoIterationNodes`, `AzDoAreaPermission`, `AzDoIterationPermission`, `AzDoWIPTags`, `AzDoProcess`, `AzDoProcessPermission` |
| Teams | `AzDoTeam`, `AzDoTeamMember`, `AzDoTeamSettings` |
| Pipelines | `AzDoPipeline`, `AzDoPipelinePermission`, `AzDoPipelineSettings`, `AzDoPipelineEnvironment`, `AzDoEnvironmentApproval`, `AzDoEnvironmentPermission`, `AzDoCheckConfiguration`, `AzDoTaskGroup`, `AzDoAgentPool`, `AzDoAgentPoolPermission`, `AzDoAgentQueue`, `AzDoDeploymentGroup` |
| Library / connections | `AzDoVariableGroup`, `AzDoVariableGroupPermission`, `AzDoServiceConnection`, `AzDoServiceConnectionPermission` |
| Artifacts | `AzDoArtifactFeed`, `AzDoArtifactFeedPermission`, `AzDoArtifactFeedSettings`, `AzDoArtifactFeedView` |
| Wiki | `AzDoWiki` |
| Generic | `AzDoSecurityNamespacePermission` |

---

## 2. Cross-cutting prerequisite — ACL token construction

Most new *permission* resources are blocked on one shared piece of work, and it should land
before (or with) the first of them.

`New-ACLToken.ps1` builds security tokens for **11** namespaces only: `Git Repositories`,
`Identity`, `CSS`, `Iteration`, `Project`, `Process`, `Build`, `Library`,
`ServiceEndpoints`, `AgentPool`, `DistributedTask`. `Parse-ACLToken.ps1` mirrors that set
and falls through to a `Generic` type for anything else.

`AzDoSecurityNamespacePermission` is the escape hatch — it takes a caller-supplied `Token`
string — but it gives the user no help constructing that token, which is the hard and
error-prone part. Every permission resource proposed below therefore needs a matching
`New-ACLToken` / `Parse-ACLToken` branch:

| New resource | Namespace | Token shape |
|---|---|---|
| `AzDoQueryPermission` | `WorkItemQueryFolders` | `$/{projectId}/{queryFolderId}[/{childFolderId}...]` |
| `AzDoDashboardPermission` | `Dashboards` / `DashboardsPrivileges` | `$/{projectId}/{teamId}/{dashboardId}` |
| `AzDoDeliveryPlanPermission` | `Plan` | `Plan/{planId}` |
| `AzDoTaggingPermission` | `Tagging` | `/{projectId}` |
| `AzDoReleaseDefinitionPermission` | `ReleaseManagement` | `{projectId}/{folderPath}/{definitionId}` |
| `AzDoSecureFilePermission` | `Library` (already supported) | existing `Library` branch |
| `AzDoPipelineFolderPermission` | `Build` (partially supported) | `{projectId}/{folderPath}` — the existing `Build` branch handles definition IDs only; see §5.4 |
| `AzDoAnalyticsPermission` | `Analytics` | `$/{projectId}` |

**Do not hardcode permission bit values.** Read them from
`_apis/securitynamespaces/{namespaceId}` and resolve by action `name`, the way the existing
ACL helpers do. Bit layouts differ per namespace and have changed between API versions.

---

## 3. Priority 1 — Work item queries (requested)

Zero coverage today. Grep for `Query` in `source/` matches only unrelated strings
(`QueryAzureMonitor`, query-string helpers).

### 3.1 `AzDoQueryFolder`

Folders are queries with `isFolder: true`; the query tree is `Shared Queries` (shareable)
and `My Queries` (per-user — out of scope for DSC, document it as unsupported).

- API: `GET|POST|PATCH|DELETE {org}/{project}/_apis/wit/queries/{path}?api-version=7.1`,
  with `$expand=all` and `$depth=N` for tree reads.
- Properties: `ProjectName` (Key), `Path` (Key, e.g. `Shared Queries/Platform/Release`),
  `Ensure`.
- Gotcha: `DELETE` on a folder deletes its whole subtree. `Remove-AzDoQueryFolder` must
  refuse to delete a non-empty folder unless `-Force`, and the class should surface that as
  a `Force` DSC property defaulting to `$false`.
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
  string comparison reports permanent drift. Normalize both sides before comparing:
  collapse whitespace, upper-case keywords, strip a trailing semicolon. Add unit tests for
  exactly this — it is the failure mode most likely to make the resource unusable.
- Prefer `PATCH` over delete-and-recreate on change: recreating changes the query GUID,
  which silently breaks any dashboard widget, delivery plan, or ACL token that references
  it.

### 3.3 `AzDoQueryPermission`

- Namespace `WorkItemQueryFolders` (id `71356614-aad7-4757-8f2c-0fb3bff6f680`).
- Token is hierarchical over **folder GUIDs**, not path names:
  `$/{projectId}/{folderId}/{subfolderId}`. So the resource must walk
  `_apis/wit/queries` resolving each path segment to its `id` before it can build a token.
  That resolution belongs in a helper (`Resolve-AzDoQueryPath`) shared with 3.1/3.2.
- Expected actions: `Read`, `Contribute`, `Delete`, `ManagePermissions` — confirm against
  the namespace API rather than trusting this list.
- Model it on `AzDoAreaPermission` (`CSS`), which has the closest shape: hierarchical
  token, `isInherited`, `Permissions` as `HashTable[]`.
- Performance warning: like the other hierarchical-namespace resources
  (`AzDoAreaPermission`, `AzDoIterationPermission`, `AzDoPipelinePermission`), this scans
  org-level ACLs and will take 200–400s per integration test. Budget for that.

---

## 4. Priority 2 — Work item tag hygiene (requested)

A companion to the existing `AzDoWIPTags`, which only ensures a tag vocabulary exists. It
does nothing about the tags that accumulate *beside* that vocabulary — `Bugfix` next to
`Bug`, `frontend` next to `Frontend`, `Tech-Debt` next to `Tech Debt`.

### 4.1 Proposed resource — `AzDoWIPTagHygiene`

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
alongside the existing `List-`/`New-`/`Remove-WITTags`.

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
  anything.
- Unit tests should cover the matcher directly (a pure function over two strings) as well
  as the resource; the matcher is where the correctness risk lives.

---

## 5. Directory / folder hierarchies

Azure DevOps exposes three folder trees that are configuration in their own right — they
carry ACLs, and objects cannot be created at a path whose folders do not exist. None is
manageable today. Because both requested query resources and several pipeline resources
depend on them, they are treated together here.

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
- Gotcha: paths are backslash-delimited and rooted at `\`. Normalize leading/trailing
  separators in the resource so `Platform\Release`, `\Platform\Release` and
  `\Platform\Release\` are one desired state rather than three.
- Renaming a folder is `POST .../folders?path={oldPath}` with the new path in the body; it
  moves every definition beneath it. Treat a `Path` change as a rename only when explicitly
  requested — otherwise a mistyped path silently relocates a whole tree. Safer default:
  treat `Path` as a Key, so a change is create-new + (optionally) remove-old.

### 5.4 `AzDoPipelineFolderPermission` — and a gap in the existing resource

The `Build` namespace is already wired into `New-ACLToken.ps1`, but **only for
definitions**: the branch resolves `ProjectId` and then a `PipelineId` from the
`LivePipelines` cache. Folder tokens have a different shape —
`{projectId}/{folderPath}` with literal path segments, not an ID — and there is no branch
for them.

Two consequences worth recording:

1. `AzDoPipelineFolderPermission` cannot be written until `New-ACLToken` /
   `Parse-ACLToken` and the `BuildPermission` localized regex in
   `AzureDevOpsDsc.Common.strings.psd1` learn the folder form.
2. The **existing** `AzDoPipelinePermission` inherits the same limitation — it cannot
   currently target a folder, so folder-inherited pipeline permissions are unmanageable
   today. This is a gap in shipped functionality, not only in the roadmap, and is worth
   confirming against a live org before the folder work starts.

### 5.5 Release folders

`AzDoReleaseFolder` / `AzDoReleaseFolderPermission` (from #59) are the third tree
(`_apis/release/folders`, `ReleaseManagement` namespace). Same modelling as 5.3/5.4. Keep
them with the classic release management phase — there is no reason to build the folder
resource ahead of the definitions it would contain.

### 5.6 Suggested sequencing

`AzDoQueryFolder` and `AzDoPipelineFolder` are independent of each other and share no code
beyond conventions, so they can be worked in parallel. Both should land **before** their
permission counterparts, and `AzDoQueryFolder` before `AzDoWorkItemQuery`.

---

## 6. Priority 3 — Verified gaps not in #59

Each of these has **zero** matches in `source/Classes/` and `source/Modules/.../Resources/`.

| Resource | Why it matters | Effort |
|---|---|---|
| `AzDoSecureFile` / `AzDoSecureFilePermission` | Certificates, keystores and signing files used by pipelines. `AzDoVariableGroup` is covered but secure files are not, and they share the `Library` namespace — the ACL token work is already done. Probably the single highest value/effort ratio on this list. | Low |
| `AzDoDashboard` / `AzDoDashboardWidget` / `AzDoDashboardPermission` | Team and project dashboards. `Dashboards` namespace needs adding. | Medium |
| `AzDoDeliveryPlan` | Cross-team roadmap plans; `Plan` namespace. | Medium |
| `AzDoElasticPool` | VMSS-backed agent pools — increasingly the default for self-hosted compute. Complements the existing `AzDoAgentPool`. | Medium |
| `AzDoGroupEntitlement` | Group-based license rules. `AzDoUserEntitlement` covers only per-user licensing, so at-scale licensing is currently unmanageable. | Low |
| `AzDoServicePrincipalEntitlement` | Workload identities / service principals as org members. The module already has `ServicePrincipalToken` and `WorkloadIdentityFederationToken` auth, so this is an inconsistency worth closing. | Low |
| `AzDoBuildRetentionSettings` | Project-level run/artifact retention (`_apis/build/retention`). | Low |
| `AzDoBoardColumn` / `AzDoBoardSettings` / `AzDoCardRule` | Board columns, swimlanes, card fields and styling. `AzDoTeamSettings` covers backlog/iteration/area defaults and working days, but not the board itself. | Medium |
| `AzDoWikiPage` | `AzDoWiki` manages the wiki, not its pages or their ordering. | Medium |

### Process customization — the largest single gap

`AzDoProcess` exposes only `ProcessName`, `ParentProcessName`, `Description`. Everything
that makes an inherited process useful is unmanaged:

- `AzDoProcessWorkItemType` — custom and inherited WITs
- `AzDoProcessField` / `AzDoCustomField` — field definitions and per-WIT assignment
- `AzDoProcessState` — custom workflow states
- `AzDoProcessRule` — conditional rules
- `AzDoProcessBehavior` — backlog behaviors
- `AzDoProcessLayout` — form pages, groups, controls
- `AzDoPicklist` — shared picklists

This is a coherent sub-project of its own and is the natural follow-on after Priority 1.
`#59` collapsed it into two bullets (`AzDoCustomField` / `AzDoWorkItemType`) under Phase 4,
which understates it considerably.

---

## 7. Reconciliation with #59

Items from #59 checked against the code:

| #59 item | Finding |
|---|---|
| `AzDoOrgPipelineSettings`, `...JobAuthorizationScope`, `...ArtifactsRetention` | **Partially covered.** `AzDoPipelineSettings` already exposes `EnforceJobAuthScope`, `EnforceJobAuthScopeForReleases`, `EnforceReferencedRepoScopedToken`, `EnforceSettableVar`, `PublishPipelineMetadata`, `StatusBadgesArePrivate`, `DisableClassicPipelineCreation`, `DisableImpliedYAMLCiTrigger` — but scoped to `ProjectName`. The gap is the **org-scoped** equivalent, not the settings themselves. Extend the existing resource with an org scope, or add one `AzDoOrgPipelineSettings`; do not add six separate resources. |
| `AzDoOrganizationPolicy` | **Overlaps** `AzDoOrganizationSettings` (`AllowPublicProjects`, `AllowExternalGuestAccess`, `EnableOAuthAuthentication`, `EnableSSHAuthentication`, `DisallowAadGuestUserPolicy`). Extend it rather than adding a resource. |
| `AzDoRepositoryDefaultBranch`, `AzDoForkPolicy` | **Already covered** by `AzDoRepositorySettings` (`DefaultBranch`, `DisableForking`, `AllowSquashMerge`, `AllowRebaseMerge`, `AllowNoFastForward`). Drop both. |
| `AzDoCommitStatusPolicy`, `AzDoPullRequestPolicySettings` | **Verify against `AzDoBranchPolicy`** before starting — likely expressible as policy types there rather than as new resources. |
| `AzDoTeamFieldValues` | **Likely covered** by `AzDoTeamSettings` (`DefaultAreaPath`, `AreaPaths`). Verify, then drop. |
| `AzDoWorkItemQuery`, `AzDoQueryFolderPermission` | **Confirmed gaps** — promoted to Priority 1 above, with folder/query/permission split out properly. |
| `AzDoPipelineRetentionPolicy` | Confirmed gap; listed above as `AzDoBuildRetentionSettings`. |
| `AzDoResourceAuthorization` | **Partially covered** by `AzDoCheckConfiguration` and the per-resource permission resources. Scope it precisely before starting. |
| `AzDoGroupEntitlement` | Confirmed gap; promoted to Priority 3. |
| `AzDoWikiPage`, `AzDoElasticPool`, `AzDoDeploymentGroupAgent`, `AzDoPipelineFolder`, dashboards, delivery plans, analytics | Confirmed gaps. |
| Classic Release Management (Phase 2 in #59) | Confirmed gap, but **recommend demoting** below Boards/Queries and Process customization. It is a legacy subsystem in maintenance mode, and it is the largest surface on the list (`AzDoReleaseDefinition` alone is comparable in size to `AzDoPipeline`). Value per unit of effort is the lowest of anything proposed. |
| Test Management (Phase 3 in #59) | Confirmed gap. Genuinely unrepresented, but demand is narrower than queries/dashboards; keep after Priority 3. |
| `AzDoBillingSettings`, `AzDoPatPolicy`, `AzDoExtensionPolicy`, `AzDoAuditLogAlert` | Confirmed gaps, tenant-scoped. Note that several of these APIs are undocumented/preview and may not be stable enough to build a resource on — spike each before committing. |

---

## 8. Status

Implemented on this branch (18 new resources, classes `101`–`116`):

| Resource | Notes |
|---|---|
| `AzDoQueryFolder`, `AzDoWorkItemQuery`, `AzDoQueryPermission` | §3. Includes WIQL normalization and `WorkItemQueryFolders` ACL token support. |
| `AzDoWIPTagHygiene` | §4. Report-only by default. |
| `AzDoSecureFile`, `AzDoSecureFilePermission` | §6. Includes the `SecureFile` form of the `Library` ACL token. |
| `AzDoPipelineFolder`, `AzDoPipelineFolderPermission` | §5.3–5.4. Includes the `Build` folder ACL token, which also closed the shipped `AzDoPipelinePermission` gap recorded in §5.4. |
| `AzDoGroupEntitlement`, `AzDoServicePrincipalEntitlement` | §6. |
| `AzDoPicklist`, `AzDoProcessWorkItemType`, `AzDoProcessField`, `AzDoProcessState`, `AzDoProcessRule`, `AzDoProcessBehavior` | §6 process customization. The "system processes are read-only" rule lives in `Resolve-AzDoProcessWorkItemType`. |

Still outstanding, in the order below:

- **Process customization** (§6) — mostly done. `AzDoPicklist`, `AzDoProcessWorkItemType`, `AzDoProcessField`, `AzDoProcessState`, `AzDoProcessRule` and `AzDoProcessBehavior` have landed (classes `111`–`116`). `AzDoProcessLayout` (form pages, groups and controls) is the remaining piece and is a sub-project of its own: the layout API is a three-level tree with its own ordering and inheritance rules, which does not fit the flat compare-and-patch shape the other five share.
- **Dashboards, delivery plans and board configuration** (§6) — `AzDoDashboard`, `AzDoDashboardWidget`, `AzDoDashboardPermission`, `AzDoDeliveryPlan`, `AzDoBoardColumn`, `AzDoBoardSettings`, `AzDoCardRule`. The `Dashboards` and `Plan` ACL namespaces are still unimplemented (§2).
- **Remaining §6 gaps** — `AzDoElasticPool`, `AzDoBuildRetentionSettings`, `AzDoWikiPage`.
- **Org-scoped pipeline settings** (§7) — extend `AzDoPipelineSettings` rather than adding six resources.
- **Test management** (§7), then **classic release management** (§7) with `AzDoReleaseFolder` (§5.5).
- **Tenant-scoped items** (§7) — `AzDoBillingSettings`, `AzDoPatPolicy`, `AzDoExtensionPolicy`, `AzDoAuditLogAlert`. Spike each first; several of these APIs are undocumented or preview.

---

## 9. Suggested order of work

1. **ACL token support** for `WorkItemQueryFolders` (§2) — unblocks 3.3.
2. **Queries**: `AzDoQueryFolder` → `AzDoWorkItemQuery` → `AzDoQueryPermission` (§3).
3. **`AzDoWIPTagHygiene`** (§4) — self-contained, no ACL dependency, can run in parallel.
4. **`AzDoSecureFile` / `AzDoSecureFilePermission`** (§6) — low effort, `Library` ACL token already exists.
5. **`AzDoPipelineFolder`** (§5.3), then the `Build` folder-token work and
   **`AzDoPipelineFolderPermission`** (§5.4) — the token work also closes a gap in the
   shipped `AzDoPipelinePermission`.
6. **`AzDoGroupEntitlement`**, **`AzDoServicePrincipalEntitlement`** (§6) — low effort each.
7. **Process customization** sub-project (§6).
8. **Dashboards / delivery plans / boards** (§6).
9. Test management, then classic release management, with `AzDoReleaseFolder` (§5.5).

Per-resource checklist (from `CLAUDE.md`): class in `source/Classes/` with the next numeric
prefix (continue from `101`), public functions under
`Resources/Functions/Public/<ResourceName>/`, unit tests mirroring that path, an integration
test using the `New-RestAuthHeader` pattern, and a rebuild + redeploy before running
integration tests.
