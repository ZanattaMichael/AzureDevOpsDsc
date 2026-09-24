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

76 class files exist, `001`–`116`; 65 of them carry `[DscResource()]` (the other 11 are the
auth and base classes). By subsystem:

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
| Pipelines | `AzDoPipeline`, `AzDoPipelinePermission`, `AzDoPipelineSettings`, `AzDoPipelineEnvironment`, `AzDoEnvironmentApproval`, `AzDoEnvironmentPermission`, `AzDoCheckConfiguration`, `AzDoTaskGroup`, `AzDoAgentPool`, `AzDoAgentPoolPermission`, `AzDoAgentQueue`, `AzDoDeploymentGroup`, `AzDoPipelineFolder`, `AzDoPipelineFolderPermission` |
| Library / connections | `AzDoVariableGroup`, `AzDoVariableGroupPermission`, `AzDoServiceConnection`, `AzDoServiceConnectionPermission`, `AzDoSecureFile`, `AzDoSecureFilePermission` |
| Artifacts | `AzDoArtifactFeed`, `AzDoArtifactFeedPermission`, `AzDoArtifactFeedSettings`, `AzDoArtifactFeedView` |
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
the variable group and the secure file form.

`AzDoSecurityNamespacePermission` is the escape hatch — it takes a caller-supplied `Token`
string — but it gives the user no help constructing that token, which is the hard and
error-prone part. Every permission resource below needs a matching `New-ACLToken` /
`Parse-ACLToken` branch:

| New resource | Namespace | Token shape | Status |
|---|---|---|---|
| `AzDoQueryPermission` | `WorkItemQueryFolders` | `$/{projectId}/{queryFolderId}[/{childFolderId}...]` | **Shipped** |
| `AzDoSecureFilePermission` | `Library` | `Library/Project/{projectId}/SecureFile/{secureFileId}` | **Shipped** |
| `AzDoPipelineFolderPermission` | `Build` | `{projectId}/{folderPath}` | **Shipped** — see §5.4 |
| `AzDoDashboardPermission` | `Dashboards` / `DashboardsPrivileges` | `$/{projectId}/{teamId}/{dashboardId}` | Outstanding |
| `AzDoDeliveryPlanPermission` | `Plan` | `Plan/{planId}` | Outstanding |
| `AzDoTaggingPermission` | `Tagging` | `/{projectId}` | Outstanding |
| `AzDoReleaseDefinitionPermission` | `ReleaseManagement` | `{projectId}/{folderPath}/{definitionId}` | Outstanding |
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
carry ACLs, and objects cannot be created at a path whose folders do not exist. Two of the
three are now manageable: query folders (§5.2) and pipeline folders (§5.3–5.4) shipped as
classes `101` and `107`–`108`. Release folders (§5.5) remain outstanding.

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

### 5.5 Release folders

`AzDoReleaseFolder` / `AzDoReleaseFolderPermission` (from #59) are the third tree
(`_apis/release/folders`, `ReleaseManagement` namespace). Same modelling as 5.3/5.4. Keep
them with the classic release management phase — there is no reason to build the folder
resource ahead of the definitions it would contain.

### 5.6 Sequencing (as executed)

`AzDoQueryFolder` and `AzDoPipelineFolder` were independent of each other and shared no
code beyond conventions. Both landed **before** their permission counterparts, and
`AzDoQueryFolder` before `AzDoWorkItemQuery`. Apply the same ordering to
`AzDoReleaseFolder` / `AzDoReleaseFolderPermission` when §5.5 is picked up.

---

## 6. Verified gaps not in #59

| Resource | Why it matters | Effort | Status |
|---|---|---|---|
| `AzDoVariableGroup` / `AzDoServiceConnection` cross-project sharing | Both objects support being shared with other projects instead of copied per project (#79). Added `SharedWithProjects`/`SharedNameOverrides` to each, backed by the shared helper `Resolve-AzDoSharedProjectReferences`; ACL tokens are unaffected since they anchor to the owning project and the object's own id. | Low | **Shipped** |
| `AzDoSecureFile` / `AzDoSecureFilePermission` | Certificates, keystores and signing files used by pipelines. They share the `Library` namespace with `AzDoVariableGroup`, so most of the ACL token work already existed. | Low | **Shipped** (`105`–`106`) |
| `AzDoGroupEntitlement` | Group-based license rules. `AzDoUserEntitlement` covers only per-user licensing. | Low | **Shipped** (`109`) |
| `AzDoServicePrincipalEntitlement` | Workload identities / service principals as org members, closing the inconsistency with the existing `ServicePrincipalToken` and `WorkloadIdentityFederationToken` auth. | Low | **Shipped** (`110`) |
| `AzDoDashboard` / `AzDoDashboardWidget` / `AzDoDashboardPermission` | Team and project dashboards. `Dashboards` namespace needs adding. | Medium | Outstanding |
| `AzDoDeliveryPlan` | Cross-team roadmap plans; `Plan` namespace. | Medium | Outstanding |
| `AzDoElasticPool` | VMSS-backed agent pools — increasingly the default for self-hosted compute. Complements the existing `AzDoAgentPool`. | Medium | Outstanding |
| `AzDoBuildRetentionSettings` | Project-level run/artifact retention (`_apis/build/retention`). | Low | Outstanding |
| `AzDoBoardColumn` / `AzDoBoardSettings` / `AzDoCardRule` | Board columns, swimlanes, card fields and styling. `AzDoTeamSettings` covers backlog/iteration/area defaults and working days, but not the board itself. | Medium | Outstanding |
| `AzDoWikiPage` | `AzDoWiki` manages the wiki, not its pages or their ordering. | Medium | Outstanding |

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
| `AzDoOrgPipelineSettings`, `...JobAuthorizationScope`, `...ArtifactsRetention` | **Partially covered.** `AzDoPipelineSettings` already exposes `EnforceJobAuthScope`, `EnforceJobAuthScopeForReleases`, `EnforceReferencedRepoScopedToken`, `EnforceSettableVar`, `PublishPipelineMetadata`, `StatusBadgesArePrivate`, `DisableClassicPipelineCreation`, `DisableImpliedYAMLCiTrigger` — but scoped to `ProjectName`. The gap is the **org-scoped** equivalent, not the settings themselves. Extend the existing resource with an org scope, or add one `AzDoOrgPipelineSettings`; do not add six separate resources. |
| `AzDoOrganizationPolicy` | **Overlaps** `AzDoOrganizationSettings` (`AllowPublicProjects`, `AllowExternalGuestAccess`, `EnableOAuthAuthentication`, `EnableSSHAuthentication`, `DisallowAadGuestUserPolicy`). Extend it rather than adding a resource. |
| `AzDoRepositoryDefaultBranch`, `AzDoForkPolicy` | **Already covered** by `AzDoRepositorySettings` (`DefaultBranch`, `DisableForking`, `AllowSquashMerge`, `AllowRebaseMerge`, `AllowNoFastForward`). Drop both. |
| `AzDoCommitStatusPolicy`, `AzDoPullRequestPolicySettings` | **Verify against `AzDoBranchPolicy`** before starting — likely expressible as policy types there rather than as new resources. |
| `AzDoTeamFieldValues` | **Likely covered** by `AzDoTeamSettings` (`DefaultAreaPath`, `AreaPaths`). Verify, then drop. |
| `AzDoWorkItemQuery`, `AzDoQueryFolderPermission` | **Closed.** Split into `AzDoQueryFolder` / `AzDoWorkItemQuery` / `AzDoQueryPermission` and shipped (§3). |
| `AzDoPipelineRetentionPolicy` | Confirmed gap; listed above as `AzDoBuildRetentionSettings`. |
| `AzDoResourceAuthorization` | **Partially covered** by `AzDoCheckConfiguration` and the per-resource permission resources. Scope it precisely before starting. |
| `AzDoGroupEntitlement` | **Closed.** Shipped as class `109` (§6). |
| `AzDoPipelineFolder` | **Closed.** Shipped as classes `107`–`108`, together with the `Build` folder ACL token (§5.3–5.4). |
| `AzDoWikiPage`, `AzDoElasticPool`, `AzDoDeploymentGroupAgent`, dashboards, delivery plans, analytics | Confirmed gaps, still outstanding. |
| Classic Release Management (Phase 2 in #59) | Confirmed gap, but **recommend demoting** below Boards/Queries and Process customization. It is a legacy subsystem in maintenance mode, and it is the largest surface on the list (`AzDoReleaseDefinition` alone is comparable in size to `AzDoPipeline`). Value per unit of effort is the lowest of anything proposed. |
| Test Management (Phase 3 in #59) | Confirmed gap. Genuinely unrepresented, but demand is narrower than queries/dashboards; keep after the §6 gaps. |
| `AzDoBillingSettings`, `AzDoPatPolicy`, `AzDoExtensionPolicy`, `AzDoAuditLogAlert` | Confirmed gaps, tenant-scoped. Note that several of these APIs are undocumented/preview and may not be stable enough to build a resource on — spike each before committing. |

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
- **Org-scoped pipeline settings** (§7) — extend `AzDoPipelineSettings` rather than adding
  six resources.
- **Test management** (§7), then **classic release management** (§7) with
  `AzDoReleaseFolder` (§5.5).
- **Tenant-scoped items** (§7) — `AzDoBillingSettings`, `AzDoPatPolicy`,
  `AzDoExtensionPolicy`, `AzDoAuditLogAlert`. Spike each first; several of these APIs are
  undocumented or preview.

---

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
6. **Org-scoped pipeline settings** (§7) — extend `AzDoPipelineSettings`.
7. Test management, then classic release management, with `AzDoReleaseFolder` (§5.5).
8. **Tenant-scoped items** (§7), each spiked before it is committed to.

Per-resource checklist (from `CLAUDE.md`): class in `source/Classes/` with the next numeric
prefix (continue from `117`), public functions under
`Resources/Functions/Public/<ResourceName>/` named `Get-`/`New-`/`Set-`/`Remove-` (the base
class resolves them by that convention, so a missing one fails at apply time), exactly one
`[DscProperty(Key)]`, no DSC property named `Force`, unit tests mirroring the public
function path, an integration test using the `New-RestAuthHeader` pattern, and a rebuild +
redeploy before running integration tests.
