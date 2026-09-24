# Change log for AzureDevOpsDscNative

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- AzureDevOpsDscNative
  - Added `AzDoOrgPipelineSettings` (#83), a resource managing the organization-scoped
    pipeline settings at `_apis/build/generalsettings` (no project segment), keyed by
    `OrganizationName`. It exposes the same eight tri-state switches as the
    project-scoped `AzDoPipelineSettings`, sharing their comparison and PATCH logic
    through new private helpers (`Get-AzDoPipelineSettingsMap`,
    `ConvertTo-AzDoPipelineSettingsLiveState`, `Compare-AzDoPipelineSettingsDrift`,
    `ConvertTo-AzDoPipelineSettingsPatch`, `Get-AzDoLockedPipelineSettings`) rather
    than duplicating them (Option B from the design discussion on #83: a separate
    class modeled on `AzDoOrganizationSettings`'s org-Key convention, instead of
    overloading `AzDoPipelineSettings` with an optional `ProjectName`, so the two
    resources keep one Key property each and their own `LockedProperties` semantics
    stay unambiguous). The three org-only switches named in #83 - disabling classic
    release pipeline creation, disabling marketplace tasks and disabling built-in/
    in-box tasks - are deferred: this container cannot reach a live organization to
    confirm their exact `generalsettings` JSON keys, and inventing them would risk
    silently PATCHing the wrong field. See `docs/ResourceRoadmap.md` for the plan to
    add them once confirmed against a live org.
  - Added an organization-lock check to `AzDoPipelineSettings`: when a switch is
    forced on by the organization-level settings, the project-scoped `Get` now
    excludes it from drift, lists it in a new `LockedProperties` result field and
    emits a `Write-Warning`, and `Set` never PATCHes a property listed there. Without this, a project desiring the switch off would
    report drift forever and `Set` would fail every apply against an org that has
    already locked it on.
  - Added `AzDoQueryFolder`, a resource managing folders in a project's shared work
    item query tree. Folders are declared in their own right so that queries can
    depend on them, rather than each query creating its own ancestry - which would
    let two queries in the same folder race to create it and make `Test()` results
    depend on apply order. Deleting a query folder in Azure DevOps deletes its whole
    subtree, so removal of a folder that still has children is refused unless
    `AllowRecursiveDelete` is set.
  - Added `AzDoWorkItemQuery`, a resource managing shared work item queries,
    including the WIQL statement, query type, display columns and sort order.
    Changes are applied in place with PATCH rather than by delete-and-recreate,
    because recreating a query changes its id and would silently break any
    dashboard widget, delivery plan or ACL token referencing it. Queries deleted
    earlier are restored from the query recycle bin instead of failing with a name
    conflict.
  - Added the private Queries API functions `Get-DevOpsQuery`, `New-DevOpsQuery`,
    `Update-DevOpsQuery` and `Remove-DevOpsQuery`.
  - Added `AzDoQueryPermission`, a resource managing the ACL on a work item query
    folder via the `WorkItemQueryFolders` security namespace. Permissions are set
    on folders and inherited by the queries beneath them; omitting `QueryPath`
    targets the project's query root. Removing the ACL on the query root is
    refused, since that token has no parent to inherit from.
  - Added `WorkItemQueryFolders` support to `New-ACLToken`, `ConvertTo-FormattedToken`
    and `Parse-ACLToken`, with the token patterns in the localized data files. The
    token addresses folders by GUID (`$/{projectId}/{folderId}/...`); because the
    project id is a GUID too, the folder chain is extracted from the remainder of
    the token so the project is not read as the first folder.
  - Added the helper `ConvertTo-NormalizedWiql`, which makes WIQL drift detection
    work. The Queries API does not return the WIQL it was given - it re-indents,
    re-wraps, re-cases and appends a semicolon - so comparing the raw strings would
    report drift on every `Test()`, forever, even when nothing had changed.
  - Added the helpers `Format-AzDoQueryPath`, which normalizes the several ways a
    query path can be written (backslashes, leading/trailing and doubled separators)
    into one canonical form, and `Resolve-AzDoQueryPath`, which walks a query path
    and collects the id of each segment - the ids that a `WorkItemQueryFolders` ACL
    token is built from.
  - Added `AzDoWIPTagHygiene`, a companion to `AzDoWIPTags` that detects work item
    tags misaligned against a canonical vocabulary (`Bugfix` beside `Bug`,
    `frontend` beside `Frontend`, `Tech-Debt` beside `Tech Debt`) and corrects them
    by renaming the tag - Azure DevOps merges a tag into an existing one on rename
    and re-tags every affected work item, so a correction costs one API call per
    tag rather than one per work item. Because a merge is irreversible and
    project-wide, the resource defaults to `RemediationAction = 'Report'`, where
    `Test()` reports drift and `Set()` lists the misalignments without changing
    anything. Tags differing only in digits (`Sprint1`/`Sprint2`, `FY24`/`FY25`)
    are never merged at any threshold, tags already in the vocabulary are never
    touched, and `MaxAutoCorrections` caps how much a misconfigured vocabulary can
    rewrite in one run.
  - Added the private API function `Update-WITTags` (tag rename/merge) and the
    helper `Get-AzDoTagMisalignment`, the pure matching logic behind the resource.
  - Added `AzDoSecureFile`, a resource managing the secure files a project makes
    available to its pipelines (certificates, keystores, provisioning profiles).
    Azure DevOps never returns a secure file's content, so `Test()` confirms the
    file exists and its properties match but cannot detect content drift; set
    `ForceUpload` to replace the content on every run. Since the API cannot update
    content in place, `ForceUpload` deletes and re-uploads, which changes the
    file's id - so any permission granted against the old id has to be re-applied.
  - Added `AzDoSecureFilePermission`, managing a secure file's ACL in the `Library`
    security namespace, and extended the `Library` ACL token with the
    `SecureFile/{id}` segment across `New-ACLToken`, `ConvertTo-FormattedToken` and
    the localized token patterns.
  - Fixed `Get-AzDoVariableGroupPermission`: its project-root Library filter matched
    any token without a variable group segment, which now also matches a secure
    file's token. The filter excludes secure file tokens explicitly.
  - Added the private API functions `List-DevOpsSecureFiles`, `New-DevOpsSecureFile`,
    `Update-DevOpsSecureFile` and `Remove-DevOpsSecureFile`, and a `LiveSecureFiles`
    cache type.
  - Added `AzDoPipelineFolder`, a resource managing the pipeline (build) folder tree.
    Paths are backslash-delimited and normalized, so the several ways a folder path
    can be written are one desired state. Deleting a pipeline folder deletes every
    definition beneath it, so removal is refused unless `AllowRecursiveDelete` is
    set - and refused as well when emptiness cannot be established, rather than
    treating a failed lookup as "empty".
  - Added `AzDoPipelineFolderPermission`, managing a pipeline folder's ACL in the
    `Build` security namespace, and added the folder token form
    (`{projectId}/{folderPath}`) to `New-ACLToken`, `ConvertTo-FormattedToken`,
    `Parse-ACLToken` and the localized patterns. Previously the `Build` branch
    understood only the definition token form, so folder-level pipeline permissions
    could not be expressed at all - including through `AzDoPipelinePermission`.
  - Added the helper `Format-AzDoPipelineFolderPath` and the private API functions
    `List-DevOpsPipelineFolders`, `New-DevOpsPipelineFolder`,
    `Update-DevOpsPipelineFolder`, `Remove-DevOpsPipelineFolder` and
    `Get-DevOpsPipelineDefinitionsInFolder`.
  - Added `AzDoGroupEntitlement`, a resource managing group licensing rules - the
    access level applied to every member of a group. `AzDoUserEntitlement` assigns
    a level one user at a time, which does not scale to an organization. Changing
    the level re-licenses the group's members; removing the rule removes nobody
    from the organization, only what the rule granted them.
  - Added `AzDoServicePrincipalEntitlement`, managing service principals and
    managed identities as organization members. Identity is matched by Microsoft
    Entra object id rather than display name, since names are neither unique nor
    stable and a rename would otherwise cause a duplicate to be created. The
    endpoint is a preview API; when an organization does not expose it, the lookup
    reports the entitlement as absent rather than failing the configuration.
  - Added `AzDoPicklist`, a resource managing picklists - the allowed values behind
    picklist-typed custom fields. Picklists are organization-scoped, so one list
    backs fields across processes. Items are replaced wholesale because the update
    endpoint takes the complete list; removing a value does not rewrite work items
    that already carry it, so they keep a value that then fails validation on the
    next edit. The list type is fixed at creation and a mismatch is reported rather
    than silently recreating the list.
  - Added `AzDoProcessWorkItemType`, managing custom and inherited work item types
    on an inherited process. Only inherited processes can be customized; naming a
    system process (Agile, Scrum, Basic, CMMI) is reported with that reason instead
    of failing against the API. Removal is destructive in two different ways - a
    custom type takes its work items with it, an inherited type discards this
    process's customizations - so both require `AllowDestructiveRemove`, with
    `IsDisabled` offered as the reversible alternative.
  - Added the helper `Resolve-AzDoProcessWorkItemType`, which resolves a process and
    work item type and enforces the "system processes are read-only" rule in one
    place, and the private API functions for picklists and process work item types.
  - Added `AzDoProcessField`, managing fields on a work item type. A field exists at
    two levels and the resource manages the second: the definition (name and type)
    is organization-scoped and shared by every work item type using the field, so
    changing it would change the field everywhere; what is per-type is required,
    default value and read-only. A new custom field's reference name is assigned by
    Azure DevOps and cannot be chosen, so fields are matched by display name and the
    reference name is read back. Removing a field detaches it rather than deleting
    it - the data on existing work items is retained.
  - Added `AzDoProcessState`, managing custom workflow states. A state's category
    (`Proposed`, `InProgress`, `Resolved`, `Completed`, `Removed`) is what boards and
    Analytics reason about, and it cannot be changed after creation: a mismatch is
    reported as an error rather than as drift, since recreating the state would
    strand every work item currently in it. Only custom states can be removed, and
    work items in a removed state keep a value that then fails validation.
  - Added the private API functions for process fields and states.
  - Added `AzDoProcessRule`, managing conditional rules on a work item type.
    Conditions and actions are passed through as the API models them rather than
    wrapped, because the vocabulary is large and grows between API versions. Drift
    detection normalizes both sides first: a configuration supplies hashtables and
    the API returns objects, and the API fills in keys the configuration omitted, so
    a raw comparison would report drift on every `Test()`. Inherited rules cannot be
    deleted, only disabled.
  - Added `AzDoProcessBehavior`, associating a work item type with a backlog level.
    This is usually the missing step when a newly created custom work item type
    appears to do nothing - without a behavior association it shows up on no backlog
    and no board. A behavior that does not exist on the process is reported as a
    configuration error rather than as a missing association.
  - Added the helper `ConvertTo-NormalizedRuleClause` and the private API functions
    for process rules and behaviors.
  - Added the private API functions `Get-DevOpsGroupEntitlement`,
    `New-DevOpsGroupEntitlement`, `Update-DevOpsGroupEntitlement`,
    `Remove-DevOpsGroupEntitlement` and their service principal equivalents. Both
    update endpoints take JSON Patch rather than a plain object.
  - Added `docs/ResourceRoadmap.md`, a verified backlog of resources still to be
    added to the module, reconciling the phased plan in issue #59 against the code.
  - Added `Get-DevOpsDescriptorIdentityBatch`, which resolves many subject
    descriptors to their ACL identities in as few `_apis/identities` calls as the
    URI will carry. Batches are packed by URI length rather than by a fixed count,
    since a subject descriptor ranges from around forty characters for a built-in
    group to well over a hundred for an AAD-backed user. A batch that fails is
    retried one descriptor at a time, so a single unresolvable identity no longer
    costs the whole batch.

### Changed

- Documentation
  - `docs/ResourceRoadmap.md` brought back in line with `main`. The 16 resources
    merged in #62 (classes `101`-`116`) were still written up as unbuilt work, and
    the coverage counts in section 1 predated them. Shipped sections are now marked
    as such and kept as the design record, with the points where the implementation
    diverged from the plan called out; the ACL token table records the shapes
    actually produced by `ConvertTo-FormattedToken`; and the order of work is
    rewritten around what is genuinely left.

- AzureDevOpsDscNative
  - The ten permission resources that still formatted a whole security namespace
    before narrowing to one token now discard the ACLs they cannot be interested in
    first, matching what `Get-AzDoProjectPermission` and `Get-AzDoProcessPermission`
    already did. `ConvertTo-FormattedACL` resolves every ACE through `Find-Identity`,
    which costs an API round trip for each descriptor that is not already cached, so
    formatting an entire namespace only to keep a single token was where the time
    went. The resources changed are `AzDoGitPermission`, `AzDoAreaPermission`,
    `AzDoPipelinePermission`, `AzDoEnvironmentPermission`,
    `AzDoServiceConnectionPermission`, `AzDoVariableGroupPermission`,
    `AzDoAgentPoolPermission`, `AzDoQueryPermission`, `AzDoSecureFilePermission` and
    `AzDoPipelineFolderPermission`.

    This is not a rare path. Each of these lookups asks the API for one token first
    and falls back to the full namespace when that returns nothing - and nothing is
    exactly what the API returns once a resource's permissions revert to inherited,
    which is the steady state. In the integration suite three `Test()` calls in that
    state accounted for 3900 of the 6749 seconds Pester spent, 58% of the run.

    Where a namespace's token pattern is anchored the filter is an exact token match,
    so it can only drop what the existing parsed filter would have dropped anyway.
    The `CSS` area paths, work item query folders and pipeline folder paths are not
    addressed by an anchored exact token, so those three filter conservatively - on
    the identifiers, or through the same `Format-AzDoPipelineFolderPath`
    normalization the parsed filter applies - and leave the parsed filter as the
    authority on what is kept.
  - `Get-AzDoGitPermission`, `Get-AzDoAreaPermission` and `Get-AzDoQueryPermission`
    no longer return `NotFound` when no ACL exists for the token they asked about.
    An absent ACL is a valid state, not a missing resource - it is what the API
    returns once permissions revert to inherited - and `NotFound` tells the base
    class `Ensure` is `Absent`, which skips `Set` and leaves the resource unable to
    apply permissions to an object that has none yet. The empty list now reaches
    `Test-ACLListforChanges`, which reads "none desired, none present" as
    `Unchanged` and "some desired, none present" as `Changed`.
  - `AzDoAPI_7_IdentitySubjectDescriptors` now resolves every group, user and service
    principal descriptor in one batched pass instead of one API call per identity.
    This was the most expensive cache initializer in the module by a wide margin: an
    organization with a few hundred identities paid a few hundred sequential round
    trips on every full cache refresh, and the round trip, not the work, was the cost.
    All three caches are resolved together rather than one at a time, so groups, users
    and service principals share batches instead of each leaving a part-full final
    request. A descriptor the API does not answer for now leaves an empty `ACLIdentity`
    rather than aborting the refresh - `Find-Identity` backfills it lazily on first use.
  - Reorganized the resource tables in `README.md`: process customization now has its
    own section with the resources in declaration order, since seven of them had
    accumulated inside "Boards and work items". Corrected the documentation section,
    which still referred to the module by its pre-rename name, and linked
    `docs/ResourceRoadmap.md` as the plan of record.
  - Updated the resource documentation for behaviour that changed:
    `AzDoPipelinePermission` now records that it targets definitions and points at
    `AzDoPipelineFolderPermission` for folders (which previously could not be
    expressed at all), and `AzDoVariableGroupPermission` documents that the `Library`
    namespace is shared with secure files and how the project-root token is
    distinguished from both.
  - Added cross-references where a resource is half of a pair: `AzDoWIPTags` to
    `AzDoWIPTagHygiene`, `AzDoProcess` to the six process customization resources,
    `AzDoUserEntitlement` to the group and service principal equivalents, and
    `AzDoSecurityNamespacePermission` to a table of the namespaces that now have
    dedicated resources.
  - Added runnable examples for `AzDoProcess`, `AzDoProcessPermission`,
    `AzDoUserEntitlement`, `AzDoServiceHook` and `AzDoPipelineSettings`, which had
    documentation pages but no `source/Examples/Resources/<Name>/` folder. Every
    resource now has one.
  - Corrected `CLAUDE.md`, which had drifted: three of the five enum tables were wrong
    (`DSCGetSummaryState` was missing `Renamed` and `Missing` and had `Error` at the
    wrong value, `RequiredAction` listed a `NoChange` member that does not exist, and
    `TokenType` listed two of its six values), `AzDoIterationPermission` and
    `AzDoPipelinePermission` were labelled as using the `CSS` namespace when they use
    `Iteration` and `Build`, and the deployed module path and expected test counts
    predated the rename. Added the resource conventions, the Linux test baseline and
    the gotchas this work surfaced.


- AzureDevOpsDscNative
  - Updated the `Dsc.PipelineRunner` documentation in `USAGE.md` and the
    "Pipeline runner initialization" example in every resource doc under
    `source/Examples/Resources` (published to the GitHub wiki on release) to
    match the latest `Dsc.PipelineRunner` release: `Invoke-AzDoLCM` is now
    `Invoke-DscPipelineRunner` (an Azure DevOps back-compat shim) or, for new
    integrations, the provider-agnostic `Invoke-DscRunner`. The
    `ConfigurationDirectory` and `ConfigurationUrl` parameters were renamed to
    `exportConfigDir` and `ConfigurationSourcePath`, and the cache directory
    environment variable is now `PIPELINERUNNER_CACHE_DIRECTORY` (with
    `AZDODSC_CACHE_DIRECTORY` retained as a back-compat alias).
  - The integration-test release gate now differentiates between a full release
    and a prerelease. A full release tag (`vX.Y.Z`) still requires every
    integration test to pass; a prerelease tag (`vX.Y.Z-<suffix>`) passes
    `allowFailures=true` to the integration workflow, so individual test failures
    are logged as warnings but the release still proceeds - preview builds can
    ship despite flaky or in-progress tests. Setup and infrastructure failures
    (Pester missing, module not resolving, no test result at all) still fail the
    gate in both modes, so a broken environment cannot silently pass. Implemented
    by an `-AllowFailures` switch on `Invoke-Tests.ps1` and an `allowFailures`
    input on `integration-tests.yml` that `publish.yml` sets from the tag.

### Added

- AzureDevOpsDscNative
  - Added a `/run-azuredevopsdscnative` skill (`.claude/skills/run-azuredevopsdscnative/`)
    with a self-contained driver script for running the Common unit suite
    headless on Linux from a clean container. Installs PowerShell 7 if missing,
    side-loads Pester 5.7.1 from `api.nuget.org` when PowerShell Gallery is
    unreachable, runs the bootstrap, and exits non-zero on test failure. Does
    not run the Classes suite (needs a built module) or the build (needs
    PSGallery-hosted Sampler/ModuleBuilder) or integration tests (need the
    self-hosted runner and a live org).
  - Added a DSC v3 integration test suite under `tests/Integration/V3/`, run by
    `Invoke-V3Tests.ps1` alongside the existing v2 suite on the self-hosted
    runner. It exercises `AzDoProject`, `AzDoGitRepository` and
    `AzDoProjectGroup` end to end through the `dsc` CLI and the PowerShell
    adapter, rather than through `Invoke-DscResource`, so the DSC v3 path is
    covered by CI. The adapter type is resolved at runtime -
    `Microsoft.Adapter/PowerShell` on DSC 3.2.0 and later, falling back to the
    deprecated `Microsoft.DSC/PowerShell` on an older CLI - and can be pinned
    with the `DSC_V3_ADAPTER` environment variable. The runner reports
    pass/fail counts and exits non-zero on failure, and honours the same
    `-AllowFailures` switch as the v2 runner, so a prerelease is not blocked by
    an in-progress v3 test.
  - Added `.github/workflows/integration-tests-v3.yml`, a standalone workflow
    for the DSC v3 suite. It is kept separate from `integration-tests.yml`
    deliberately: the v2 suite takes the better part of an hour, so running v3
    inside it means waiting v2 out to learn anything about v3. Split, the two
    can be dispatched, gated and re-run independently, and since both target the
    same self-hosted runner they queue rather than contend. The workflow builds
    the module, pins `PSModulePath` to that single build, installs the `dsc`
    CLI, runs `Invoke-V3Tests.ps1` and uploads
    `v3-integration-test-results.xml`. `publish.yml` calls it as a second
    release gate beside the v2 gate, with the same prerelease `allowFailures`
    rule, so a release still gates on both suites.
  - Added `tests/Integration/V3/Manifests/DscV3Manifests.tests.ps1`, covering the
    DSC v3 adapted resource manifests that `build.ps1 -Tasks dscv3` generates.
    Nothing was checking them, and their failure mode is silent:
    `DscResource.Authoring` derives each property's JSON schema type from the
    AST type name, which yields `System.Boolean` for this module's convention
    rather than the `bool` its type map expects, so the property quietly falls
    back to `"string"`. `Fix_DscAdaptedResourceManifestTypes` repairs that after
    generation - 25 of the 49 manifests need it - but if that task stops running
    or stops matching, every boolean and numeric property becomes a string again
    and the build still goes green. The suite asserts a manifest exists for every
    `[DscResource()]` class, that each declares the right type and the built
    module version, that every property's schema type matches the type its class
    declares, that no configurable `[DscProperty()]` is missing, that the
    combined manifest list agrees with the individual files (they are generated
    and patched separately, so they can drift), and that the `dsc` CLI can
    actually discover the resources through the adapter. Class shapes are read
    from the built module's AST, including inherited properties, so the checks do
    not need a DSC host able to load the module.
- AzureDevOpsDsc
  - Added DSC v3 support: all 49 class-based DSC resources now declare `Set()`
    and `Test()` directly (delegating to `AzDevOpsDscResourceBase`) instead of
    relying on pure inheritance, so both the `Microsoft.Adapter/PowerShell`
    runtime adapter and `DscResource.Authoring`'s manifest generator correctly
    detect `get`/`set`/`test` capabilities instead of only `get`.
  - Added a `dscv3` build workflow (`Create_DscAdaptedResourceManifests`,
    `Create_DscResourceManifestsList` from `DscResource.Authoring`) that
    generates DSC v3 adapted resource manifests for every resource into the
    built module output, and wired it into `pack`.
  - Renamed the module from `AzureDevOpsDsc` to `AzureDevOpsDscNative` for
    publishing under this fork, since PowerShell Gallery names are globally
    unique and this repo doesn't own the existing `AzureDevOpsDsc` listing.
  - Added GitHub Actions workflows: `build.yml` (build + generate DSC v3
    manifests as CI artifacts on every push/PR), `unit-tests.yml` (runs the
    Classes and Common unit test suites), and `publish.yml` (tag-triggered
    release: builds, re-runs both test suites as a release gate, packages the
    module, and publishes a GitHub Release plus - once a Gallery API key is
    configured - PowerShell Gallery).
  - Updated pipeline files to support change of default branch to main.
  - Added GitHub issue templates and pull request template
  ([issue #1](https://github.com/dsccommunity/AzureDevOpsDsc/issues/1))
  - Added the `AzDevOpsProject`, DSC Resource
  - Fixed non-terminating, integration tests ([issue #18](https://github.com/dsccommunity/AzureDevOpsDsc/issues/18))
  - Increased Azure DevOps, API timeout to 5 minutes to allow for busy/slow API
    operations ([issue #25](https://github.com/dsccommunity/AzureDevOpsDsc/issues/25)).
  - Updated contextual help ([issue #5](https://github.com/dsccommunity/AzureDevOpsDsc/issues/5)).
  - Removed `Classes` directory from being output in packaged module ([issue #10](https://github.com/dsccommunity/AzureDevOpsDsc/issues/10)).
  - Removed `Examples` directory from being output in packaged module ([issue #11](https://github.com/dsccommunity/AzureDevOpsDsc/issues/11)).
  - Moved 'Ensure' and 'RequiredAction' enums into 'Enum' directory and out of
    'prefix.ps1' ([issue #12](https://github.com/dsccommunity/AzureDevOpsDsc/issues/12)).
  - Added pipeline support for publish markdown content to the GitHub repository
    wiki ([issue #15](https://github.com/dsccommunity/AzureDevOpsDsc/issues/15)).
    This will publish the markdown documentation that is generated by the build pipeline.
  - Added new source folder `WikiSource`. Every markdown file in the folder
    `WikiSource` will be published to the GitHub repository wiki. The markdown
    file `Home.md` will be updated with the correct module version on each
    publish to gallery (including preview).
  - CodeCov integration.
- Added Resources:
  - AzDoGroupPermission
  - AzDoOrganizationGroup
  - AzDoProjectGroup
  - AzDoGroupMember
  - AzDoGitRepository
  - AzDoGitPermission
  - AzDoTeamSettings
  - AzDoArtifactFeedSettings
  - AzDoArtifactFeedView
  - AzDoProcess
  - AzDoProcessPermission
  - AzDoAgentPool
  - AzDoAgentPoolPermission
  - AzDoAgentQueue
  - AzDoAreaNodes
  - AzDoAreaPermission
  - AzDoArtifactFeed
  - AzDoArtifactFeedPermission
  - AzDoAuditStream
  - AzDoBranchPolicy
  - AzDoCheckConfiguration
  - AzDoDeploymentGroup
  - AzDoEnvironmentApproval
  - AzDoEnvironmentPermission
  - AzDoExtension
  - AzDoIterationNodes
  - AzDoIterationPermission
  - AzDoNotificationSubscription
  - AzDoOrganizationSettings
  - AzDoPipeline
  - AzDoPipelineEnvironment
  - AzDoPipelinePermission
  - AzDoProject
  - AzDoProjectPermission
  - AzDoProjectServices
  - AzDoRepositorySettings
  - AzDoSecurityNamespacePermission
  - AzDoServiceConnection
  - AzDoServiceConnectionPermission
  - AzDoTaskGroup
  - AzDoTeam
  - AzDoTeamMember
  - AzDoVariableGroup
  - AzDoVariableGroupPermission
  - AzDoWIPTags
  - AzDoWiki
  - AzDoUserEntitlement
  - AzDoServiceHook
  - AzDoPipelineSettings
- AzureDevOpsDsc.Common
  - Added New-AzDoAuthenticationProvider. This is invoked prior to the resource invocation.
  - Added 'wrapper' functionality around the [Azure DevOps REST API](https://docs.microsoft.com/en-us/rest/api/azure/devops/)
  - Added Supporting Functions for Azure Managed Identity.
- Added Unit Testing to AzureDevOpsDsc.Common


### Changed

- AzureDevOpsDscNative
  - Made the integration test suite a hard release gate. `publish.yml` is now
    split into `validate`, `integration-tests` and `publish` jobs, where
    `publish` depends on `integration-tests`; the integration job calls
    `integration-tests.yml` as a reusable workflow (rather than duplicating it)
    and builds the exact version being released. No GitHub Release and no
    PowerShell Gallery package is produced unless every integration test passes.
    The integration job runs as an ordinary Actions job on the self-hosted
    `AZDO-AGENT` runner - it does not use a GitHub Environment, so there is no
    deployment record or manual approval gate, and `AZURE_DEVOPS_PAT` and
    `AzureDevOpsOrg` must be repository-level rather than Environment-scoped.
  - Reworked the release process so that a released version has exactly one
    source of truth - the git tag. `publish.yml` now also verifies the tag is
    contained in `main` before releasing, accepts prerelease tags of the form
    `vX.Y.Z-preview0001`, and runs the `docs` tasks during packaging so the
    published package ships conceptual help. The `moduleVersion` in the module
    manifest and `next-version` in `GitVersion.yml` are documented as build
    fallbacks and brought into agreement with each other.
  - Added a changelog roll-over step to `publish.yml`
    (`Create_ChangeLog_GitHub_PR`), so a release converts the `[Unreleased]`
    section into a versioned one instead of carrying its entries into the next
    release.
  - Moved `Publish_GitHub_Wiki_Content` out of the `publish` task chain in
    `build.yaml` and into a separate non-blocking step, so a wiki failure can no
    longer fail a release whose Gallery package has already been published.
  - Added a `docs` step to `build.yml` so documentation generation is exercised
    on every push and pull request rather than for the first time during a
    release.
  - Documented the full release procedure and required repository secrets in
    `CONTRIBUTING.md`, and corrected the `Releases` section of `README.md`,
    which described an automatic preview release on every merge to `main` that
    this fork's workflows never performed.
- AzureDevOpsDsc
  - Enabled integration tests against https://dev.azure.com/azuredevopsdsc/ (see
    comment https://github.com/dsccommunity/AzureDevOpsDsc/issues/9#issuecomment-766375424
    for more information).
  - Updated pipeline file `RequiredModules.ps1` to latest pipeline pattern.
  - Updated pipeline file `build.yaml` to latest pipeline pattern.
  - Updated pipeline file `azure-pipelines.yml` to use correct images (hosted runners)
    and correct task for artifacts.
  - Enhanced Authentication Mechanisms.
    The classes have been refactored to accommodate a variety of authentication methods.
    This refactoring allows the system to support multiple authentication
    protocols, enhancing security and providing flexibility in integrating with
    different identity providers.
  - Added LookupResult Property to classes. A new property, LookupResult,
    has been introduced to the classes. This addition enables the classes to
    efficiently store and retrieve lookup results, improving data handling
    capabilities and streamlining processes that depend on quick access
    to these results.
  - Added [DSCGetSummaryState] class. : Introduced an additional class,
    [DSCGetSummaryState], which serves to represent the changes that have been detected.
  - The Get() and Test() methods have undergone a redesign.
    The Get-* commands now efficiently retrieve and identify complex changes,
    which are then depicted within the [DSCGetSummaryState] class.
- AzDevOpsProject
  - Added a validate set to the parameter `SourceControlType` to (for now)
    limit the parameter to the values `Git` and `Tfvc`.
  - Update comment-based help to remove text which the valid values are
    since that is now add automatically to the documentation (conceptual
    help and wiki documentation).
- Update build.yaml tests reference:
  - Added: ./azuredevopsdsc.common.tests.ps1
  - Added: ./azuredevopsdsc.tests.ps1
- Repository Updates
  - Update repository files to latest versions.
    - Resolve-Dependency
    - build.yml
    - Sampler files
    - azure-pipelines

### Fixed

- AzureDevOpsDscNative
  - Fixed the Windows PowerShell integration workflow (`integration-tests.yml`)
    testing the resource classes of a stale, hand-deployed copy of the module
    rather than the ones the job had just built. Every `shell: pwsh` step is a new
    `pwsh` started by the runner, and such a `pwsh` re-adds the default module
    directories to the `PSModulePath` it inherits - the runner's profile directory,
    where `scripts/redeploy-module.ps1` deploys `AzureDevOpsDscNative`, among them.
    The workflow's `PSModulePath` rewrite, and the single-copy assertion made with
    it, therefore held only in their own step, and `Invoke-DscResource` in the test
    step loaded the classes from the profile copy. Changes to resource functions
    were exercised correctly, but a pull request adding a class property failed
    with `The property '<Name>' cannot be found on this object`, and one relaxing a
    `ValidateSet` still had the old set enforced. The workflow now shelves those
    copies for the duration of the job and restores them in an `always()` step, in
    the same way (and with the same record format) as `integration-tests-v3.yml`,
    and repeats the single-copy assertion in the test step itself.
  - Fixed every live `dsc resource get/set/test` call in the DSC v3 integration
    suite failing with `Cannot convert the "System.Object[]" value ... to type
    "System.Management.Automation.PSModuleInfo"` - 25 failures across the
    `AzDoGitRepository`, `AzDoProject` and `AzDoProjectGroup` suites, while
    discovery (`dsc resource list`) stayed green. `dsc.exe` runs the PowerShell
    adapter in a child `pwsh` it launches itself, and a `pwsh` started from a
    parent that is not PowerShell prepends the default module directories to
    whatever `PSModulePath` it inherited. The runner's profile directory - which
    holds a hand-installed `DscResource.Common` and whatever
    `scripts/redeploy-module.ps1` last deployed - therefore came back inside the
    adapter's session, ahead of the built module, no matter what the workflow set
    `PSModulePath` to. The adapter imports the built module by `.psm1` path, and
    the first command only the other copy exports auto-loads it as a second module
    of the same name; `Invoke-DscCacheRefresh`'s fast path then hands
    `Get-Module -Name`'s array to a `[PSModuleInfo]` parameter and throws. Listing
    survived because the slow path it takes de-duplicates by version. The workflow
    now moves conflicting profile-scope and machine-scope copies aside for the
    duration of the job and restores them in an `always()` step, and re-asks the
    single-copy question in a `pwsh` launched through `cmd.exe` - a native parent,
    as `dsc.exe` is - so the assertion checks the path the adapter actually sees
    rather than the one this job controls.
  - Fixed the DSC v3 integration workflow failing its own duplicate-module
    assertion before any test ran, with `Module 'DscResource.Common' resolves
    from 2 locations`. The workflow installed Pester with `-Scope CurrentUser`,
    which puts it in the self-hosted runner's profile module directory - and that
    directory also carries a hand-installed `DscResource.Common`, so keeping it on
    `PSModulePath` for Pester's sake handed `DscResource.Common` a second location
    alongside the copy bundled in the built module. `integration-tests.yml` already
    solved this by saving Pester to `./output/TestModules` and dropping the profile
    directory from the path; `integration-tests-v3.yml` now does the same, and
    checks Pester 5 is still resolvable on the rewritten path rather than letting
    `Invoke-V3Tests.ps1` fail its `#Requires` later.
  - Fixed `Find-Identity` throwing `You cannot call a method on a null-valued
    expression` when a cached organization group has a null or empty
    `principalName`. The principalName group filter called `.replace()` on the
    value unguarded, which aborted every ACL resolution
    (`Get-AzDo*Permission` -> `ConvertTo-ACL` -> `ConvertTo-ACEList` ->
    `Find-Identity`) and failed all permission resources. A malformed group can
    never be the target of a principalName search, so it is now excluded from that
    filter. This surfaced once the `AzDoAPI_7_IdentitySubjectDescriptors` fix below
    stopped the cache refresh aborting early, letting such a group reach
    `Find-Identity`.
  - Fixed `AzDoAPI_7_IdentitySubjectDescriptors` throwing `Cannot bind argument to
    parameter 'SubjectDescriptor' because it is an empty string` when an
    organization group, user, or service principal has an empty descriptor. The
    mandatory-parameter bind aborted the entire cache refresh, and with it any
    `AzDoProject` Set/Test that triggered it (3 integration test failures). Each
    identity loop now skips entries with no descriptor, which cannot be resolved
    anyway ([issue #43](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/43)).
  - Fixed `New-WITTags` so a `Set` that has returned guarantees the created tags
    are observable. Azure DevOps creates tags only as a side effect of a work item
    and the `/wit/tags` list is eventually consistent, so adding several tags and
    immediately testing could report not-in-desired-state
    (`AzDoWIPTags` "add and remove multiple tags"). The function now confirms the
    new tags are listable, with a short time-boxed retry, before returning
    ([issue #44](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/44)).
  - Fixed the Integration Tests workflow, which could never have run the suite.
    Three independent blockers, all masked until `Invoke-Tests.ps1` was made to
    report failures. (1) The self-hosted runner does not ship Pester 5 while
    `Invoke-Tests.ps1` declares a `#Requires` for it - this was the only one of the
    three workflows with no `Install Pester` step. (2) The workflow put only
    `./output` on `PSModulePath` when the built module lives at
    `output/builtModule/<Module>/<Version>` with its nested modules one level
    further down, so `Initalize-TestFramework.ps1` could not import
    `AzureDevOpsDsc.Common`. (3) Once those directories were added, several modules
    resolved from more than one location - `DscResource.Common` from both the built
    module's bundled `Modules` folder and `output/RequiredModules`, plus stale
    hand-deployed copies under `C:\Temp\DSCModule` on the runner - which made
    `Get-Module` return an array and DSC's `GetResourceFromKeyword` throw
    `Cannot convert System.Object[] to PSModuleInfo` inside every `Invoke-DscResource`,
    failing all 381 tests. `PSModulePath` is now set to exactly one copy of each
    module and the step asserts single-location resolution before the suite starts.
  - Fixed `tests/Integration/Invoke-Tests.ps1`, which called `Invoke-Pester`
    without `PassThru` and never inspected the result. The script always exited
    `0`, so a run with failing integration tests was indistinguishable from a
    passing one and the Integration Tests workflow reported success regardless.
    It now returns a non-zero exit code when any test fails, after the post-run
    teardown so a failing run still cleans up after itself.
  - Renamed every functional reference to the module from `AzureDevOpsDsc` to
    `AzureDevOpsDscNative` (347 across 181 files): `Import-DscResource
    -ModuleName` and `Invoke-DscResource -ModuleName` in all examples, the
    `type: AzureDevOpsDsc/<Resource>` entries in the DSC v3 configuration
    documents, and the resource references in the wiki source. These named a
    module that is not installed under that name, so the examples as published
    could not run. References to the nested `AzureDevOpsDsc.Common` module, the
    historical changelog entries, and the upstream fork attribution in
    `README.md` and `SECURITY.md` are deliberately unchanged.
  - Retargeted the `AzDevOpsProject` examples onto `AzDoProject`, the resource
    that actually exists, and renamed the example directory to match. They were
    the only project examples in the repository and documented the same phantom
    resource that was removed from `DscResourcesToExport`.
  - Corrected repository URLs that pointed at the upstream project: the issues
    and changelog links in `source/WikiSource/Home.md`, and the `.LINK` entries
    in `041.AzDoGitPermission.ps1` and `Get-CacheObject.ps1` now point at this
    fork. The fork-attribution links in `README.md` and `SECURITY.md`, and the
    historical `dsccommunity` issue links in this changelog, correctly still
    point upstream.
  - Fixed `Set-OutputDirAsModulePath` in the unit test helpers, which added a
    hardcoded `output\AzureDevOpsDsc\0.0.0\Modules` path to `PSModulePath` -
    wrong module name, a version that has never existed, and predating the
    `builtModule` subdirectory, so it never resolved. The path is now globbed
    from the built module output, the same fix applied to the `PreLoad` task.
  - Fixed the `docs` build task, which failed with `Cannot index into a null
    array` and broke the Build workflow. The comment-based help in
    `042.AzDoAreaPermission.ps1` and `043.AzDoIterationPermission.ps1` used a
    `.METHOD` keyword, which PowerShell's help parser does not recognise - it
    rejects the entire help block and `GetHelpContent()` returns `$null`, which
    `DscResource.DocGenerator`'s `New-DscResourcePowerShellHelp` then indexes
    into. The method documentation is folded into `.NOTES` instead, and the
    placeholder `<link to the GitHub repository>` in both `.LINK` sections is
    replaced with the actual repository URL. All 49 resource classes now produce
    conceptual help.
  - Removed `AzDevOpsProject` from `DscResourcesToExport`. No class, MOF schema,
    or any other implementation of that resource exists - it is a leftover from
    the upstream module - so the manifest advertised 50 resources while shipping
    49, and the Gallery listing would have claimed a resource that could never
    be found by `Get-DscResource`. Also added a missing comma after
    `AzDoProcessPermission` in the same list.
  - Removed the `build-publish.yml` workflow. It triggered on the same version
    tags as `publish.yml`, so every release ran two competing publishes. Its
    publish job could never succeed - it looked for the built module at
    `output/AzureDevOpsDsc`, a path that predates the rename to
    `AzureDevOpsDscNative` and the move to `output/builtModule` - and had it
    succeeded it would have published version `0.0.2` regardless of the tag,
    used a different Gallery secret name, and bypassed the unit test gate. It
    also built the module a third redundant time on every pull request.
  - Fixed the `PreLoad` build task, which added a hardcoded
    `output/AzureDevOpsDsc/0.0.1/Modules` path to `PSModulePath`. Neither the
    module name nor the version had been correct since the rename, and the path
    also predates the move to the `builtModule` subdirectory, so the nested
    modules were never actually added. The version cannot be hardcoded at all
    now that it comes from the release tag, so the path is resolved by globbing
    the built module output instead. The task now also adds
    `output/RequiredModules`, and skips paths that do not exist rather than
    adding unusable entries to `PSModulePath`.
  - Fixed an intermittent Pester class-loading race in the Classes unit test
    suite (`Could not find type [X]`) by switching from dot-sourcing raw
    source classes to `using module` against the built module - the Classes
    suite now passes 211/211 deterministically, verified on a cold GitHub
    Actions runner (not just locally).
  - Fixed 29 pre-existing failures in the Common unit test suite that had
    never been visible in CI (the suite was always blocked by the Classes
    suite failing first): a `Write-Error` pattern that becomes terminating
    under this runner's `$ErrorActionPreference` across 17 permission
    functions, a null-array aggregation bug in `List-DevOpsAgentPools`, an
    extension-method resolution issue in `Build-JWTAssertion`, unreliable
    `$LASTEXITCODE` propagation across a Pester mock boundary in
    `Get-AzCliToken`, culture-dependent date parsing in `Test-Date`, a stale
    test assertion in `Test-ACLListforChanges`, several tests missing an
    explicit dependency dot-source, and a mock incompatible with a typed
    parameter in `Get-AzServicePrincipalCertificateToken`. The Common suite
    now passes 1703/1703 (10 intentionally skipped), also verified on CI.
  - Fixed `Wait-DevOpsProject` never observing a completed project, so every
    `AzDoProject` New or Set spent the full ten-attempt poll (50 seconds) before
    returning. Two defects compounded: the `break` statements inside the status
    `switch` broke out of the enclosing `while` rather than the switch, so the
    loop exited on its first iteration through the error branch; and the switch
    only knew the *project* status vocabulary (`creating`/`wellFormed`/`failed`)
    while both callers pass an *operations* URL - `POST /_apis/projects` and
    `PATCH /_apis/projects/{id}` each return a 202 operation reference pointing
    at `/_apis/operations/{id}`, which reports `queued`, `inProgress`,
    `succeeded` or `cancelled` and never `wellFormed`. Every poll therefore fell
    through to `default`, slept, and exhausted its attempts on a project that had
    in fact been created. The switch now matches both vocabularies and no longer
    breaks the loop from inside a case.
  - Fixed `Remove-DevOpsGroup`, `New-DevOpsGroupMember` and
    `Remove-DevOpsGroupMember` failing with `VssInvalidPreviewVersionException`.
    All three defaulted their API version to `Get-AzDevOpsApiVersion -Default`
    (`7.1`), but the graph API is preview-only and rejects a plain `7.1`. They
    now pin `7.1-preview.1`, matching the eleven other graph call sites in the
    module - including `New-`/`Remove-DevOpsTeamMember`, which hit the same
    `/_apis/graph/memberships/` endpoint.
  - Fixed `Refresh-AzDoCache` rebuilding every cache on each call. It now accepts
    a `-CacheType` parameter and runs only the initializers that feed the caches
    named, falling back to a full refresh when a name is unrecognised.
    `New-AzDoProject` and `Set-AzDoProject` now ask for `LiveProjects` alone
    rather than every cache, which is what dominated the DSC v3 integration run
    time: the PowerShell adapter spawns a fresh
    process per `dsc resource` call, so a full refresh was paid on every
    invocation. The initializers are dot-sourced and assign a local `$CacheType`
    of their own, which collided with the new parameter and handed
    `Add-CacheItem -Type` a `[string[]]`; they are now dot-sourced through a
    scriptblock so they get a scope of their own rather than this function's.
  - Fixed the `AzDoTaskGroup` and `AzDoDeploymentGroup` integration tests failing
    against an organization that disables classic pipelines. Task groups and
    deployment groups are classic-pipeline objects, and creating one is refused
    with `400 Bad Request - "The classic pipelines are disabled for this project /
    organization."` whenever the "Disable creation of classic build and release
    pipelines" policy is on - the default for newer Azure DevOps organizations -
    which failed eight tests and, through `publish.yml`, the release gate. Both
    suites now call a new `Enable-TestClassicPipeline` helper, which turns the
    policy off for their own test project through the same two settable fields
    `AzDoPipelineSettings` drives and reads the result back rather than assuming
    the PATCH took effect. Where an organization-level policy pins the setting on
    and the resource cannot be exercised at all, the tests that need to create the
    object report as skipped instead of failing.

- AzDevOpsProject
  - Added description to the comment-based help.
