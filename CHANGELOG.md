# Change log for AzureDevOpsDscNative

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

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

- AzDevOpsProject
  - Added description to the comment-based help.
