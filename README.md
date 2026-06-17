# AzureDevOpsDsc

The **AzureDevOpsDsc** module contains DSC Resources for deployment and
configuration of Azure DevOps and Azure DevOps Server.

[![Build Status](https://dev.azure.com/dsccommunity/AzureDevOpsDsc/_apis/build/status/dsccommunity.AzureDevOpsDsc?branchName=main)](https://dev.azure.com/dsccommunity/AzureDevOpsDsc/_build/latest?definitionId=41&branchName=main)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/AzureDevOpsDsc/41/main)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/AzureDevOpsDsc/41/main)](https://dsccommunity.visualstudio.com/AzureDevOpsDsc/_test/analytics?definitionId=41&contextType=build)
[![codecov](https://codecov.io/gh/dsccommunity/AzureDevOpsDsc/branch/main/graph/badge.svg)](https://codecov.io/gh/dsccommunity/AzureDevOpsDsc)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/AzureDevOpsDsc?label=AzureDevOpsDsc%20Preview)](https://www.powershellgallery.com/packages/AzureDevOpsDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/AzureDevOpsDsc?label=AzureDevOpsDsc)](https://www.powershellgallery.com/packages/AzureDevOpsDsc/)

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Usage

Please review the following [Usage Documentation](USAGE.md)

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

Additionally, please [`AzureDevOpsDsc` contribution guidelines](CONTRIBUTING.md)
for more information about contributing to this module (including an overview of
module structure, design and setup of Integration tests).

## Testing

This module is tested with [Pester 5](https://pester.dev/). Tests live under
[`tests/`](tests) and are split into:

- **Unit tests** ([`tests/Unit`](tests/Unit)) — fast, no external dependencies.
- **Integration tests** ([`tests/Integration`](tests/Integration)) — run against a
  live Azure DevOps organization and require authentication.

### Test tags

Every `Describe` block is tagged with a **type** tag and a **service** tag:

- **Type tag** — `Unit` or `Integration`.
- **Service tag** — the resource/service the test covers (for example
  `ArtifactFeed`, `Project`, `GitPermission`). The same service tag is applied to a
  service's unit *and* integration tests, so one tag selects both.

Some unit tests also keep an additional category tag (`API`, `Cache`, `ACL`,
`Helper`, `Authentication`).

```powershell
Invoke-Pester -Tag Unit            # all unit tests
Invoke-Pester -Tag Integration     # all integration tests
Invoke-Pester -Tag ArtifactFeed    # unit + integration for one service
Invoke-Pester -Tag Unit, API       # unit tests for the private API functions
```

### Running the unit tests

```powershell
# Build the module first so the compiled module and classes are available.
./build.ps1 -Tasks build

Invoke-Pester -Path ./tests/Unit -Tag Unit
```

### Running the integration tests

Integration tests create and tear down real Azure DevOps resources, so they run
through a test framework that handles authentication, setup and teardown. Set the
cache directory, then invoke the framework:

```powershell
$env:AZDODSC_CACHE_DIRECTORY = '<path-to-a-writable-cache-folder>'

Set-Location ./tests/Integration
. ./Invoke-Tests.ps1 -TestFrameworkConfigurationPath ./TestFrameworkConfiguration.json
```

To iterate on a subset (specific files and/or `Context` blocks) without running the
whole suite, use the targeted runner:

```powershell
. ./Invoke-TargetedTests.ps1 `
    -TestFrameworkConfigurationPath ./TestFrameworkConfiguration.json `
    -TestFile AzDoArtifactFeed `
    -FullName '*Creating*'
```

See [`tests/README.md`](tests/README.md) for the full tag taxonomy and more detail.

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

Each resource links to its example/usage documentation.

### Projects, organization, groups and teams

| Resource | Description |
|---|---|
| [AzDoProject](source/Examples/Resources/AzDoProject.md) | Creates and manages Azure DevOps projects. |
| [AzDoProjectServices](source/Examples/Resources/AzDoProjectServices.md) | Enables or disables services (Repos, Boards, Pipelines, Test Plans, Artifacts) within a project. |
| [AzDoOrganizationSettings](source/Examples/Resources/AzDoOrganizationSettings.md) | Manages organization-level settings. |
| [AzDoProjectGroup](source/Examples/Resources/AzDoProjectGroup.md) | Creates and manages groups within a project. |
| [AzDoOrganizationGroup](source/Examples/Resources/AzDoOrganizationGroup.md) | Creates and manages groups at the organization level. |
| [AzDoGroupMember](source/Examples/Resources/AzDoGroupMember.md) | Manages membership of users, groups and service principals in a group. |
| [AzDoTeam](source/Examples/Resources/AzDoTeam.md) | Creates and manages teams within a project. |
| [AzDoTeamMember](source/Examples/Resources/AzDoTeamMember.md) | Manages membership of a team. |

### Repositories and policies

| Resource | Description |
|---|---|
| [AzDoGitRepository](source/Examples/Resources/AzDoGitRepository.md) | Creates and manages Git repositories within a project. |
| [AzDoRepositorySettings](source/Examples/Resources/AzDoRepositorySettings.md) | Manages Git repository settings. |
| [AzDoBranchPolicy](source/Examples/Resources/AzDoBranchPolicy.md) | Manages branch policies (e.g. minimum reviewer count) on a repository. |

### Permissions

| Resource | Description |
|---|---|
| [AzDoProjectPermission](source/Examples/Resources/AzDoProjectPermission.md) | Manages project-level permissions for identities. |
| [AzDoGitPermission](source/Examples/Resources/AzDoGitPermission.md) | Manages fine-grained Git repository permissions for identities. |
| [AzDoAreaPermission](source/Examples/Resources/AzDoAreaPermission.md) | Manages area path (classification node) permissions. |
| [AzDoIterationPermission](source/Examples/Resources/AzDoIterationPermission.md) | Manages iteration path (classification node) permissions. |
| [AzDoAgentPoolPermission](source/Examples/Resources/AzDoAgentPoolPermission.md) | Manages agent pool permissions. |
| [AzDoEnvironmentPermission](source/Examples/Resources/AzDoEnvironmentPermission.md) | Manages pipeline environment permissions. |
| [AzDoPipelinePermission](source/Examples/Resources/AzDoPipelinePermission.md) | Manages build/pipeline permissions. |
| [AzDoServiceConnectionPermission](source/Examples/Resources/AzDoServiceConnectionPermission.md) | Manages service connection (endpoint) permissions. |
| [AzDoVariableGroupPermission](source/Examples/Resources/AzDoVariableGroupPermission.md) | Manages variable group (library) permissions. |
| [AzDoArtifactFeedPermission](source/Examples/Resources/AzDoArtifactFeedPermission.md) | Manages artifact feed permissions. |
| [AzDoSecurityNamespacePermission](source/Examples/Resources/AzDoSecurityNamespacePermission.md) | Manages permissions for an arbitrary security namespace and token. |
| [AzDoGroupPermission](source/Examples/Resources/AzDoGroupPermission.md) | *(Not currently supported)* Manages group-level identity permissions. |

### Pipelines, environments and agents

| Resource | Description |
|---|---|
| [AzDoPipeline](source/Examples/Resources/AzDoPipeline.md) | Creates and manages YAML pipeline definitions. |
| [AzDoPipelineEnvironment](source/Examples/Resources/AzDoPipelineEnvironment.md) | Creates and manages pipeline environments. |
| [AzDoEnvironmentApproval](source/Examples/Resources/AzDoEnvironmentApproval.md) | Manages approval checks on a pipeline environment. |
| [AzDoCheckConfiguration](source/Examples/Resources/AzDoCheckConfiguration.md) | Manages pipeline checks (e.g. Approval) on a protected resource. |
| [AzDoDeploymentGroup](source/Examples/Resources/AzDoDeploymentGroup.md) | Creates and manages deployment groups. |
| [AzDoAgentPool](source/Examples/Resources/AzDoAgentPool.md) | Creates and manages organization agent pools. |
| [AzDoAgentQueue](source/Examples/Resources/AzDoAgentQueue.md) | Creates and manages project agent queues. |
| [AzDoTaskGroup](source/Examples/Resources/AzDoTaskGroup.md) | Creates and manages task groups. |
| [AzDoVariableGroup](source/Examples/Resources/AzDoVariableGroup.md) | Creates and manages variable groups (library). |
| [AzDoServiceConnection](source/Examples/Resources/AzDoServiceConnection.md) | Creates and manages service connections (service endpoints). |

### Boards and work items

| Resource | Description |
|---|---|
| [AzDoAreaNodes](source/Examples/Resources/AzDoAreaNodes.md) | Manages area path classification nodes. |
| [AzDoIterationNodes](source/Examples/Resources/AzDoIterationNodes.md) | Manages iteration path classification nodes. |
| [AzDoWIPTags](source/Examples/Resources/AzDoWIPTags.md) | Manages work item tags. |
| [AzDoNotificationSubscription](source/Examples/Resources/AzDoNotificationSubscription.md) | Manages notification subscriptions. |

### Artifacts, wiki, extensions and auditing

| Resource | Description |
|---|---|
| [AzDoArtifactFeed](source/Examples/Resources/AzDoArtifactFeed.md) | Creates and manages artifact feeds. |
| [AzDoWiki](source/Examples/Resources/AzDoWiki.md) | Creates and manages project and code wikis. |
| [AzDoExtension](source/Examples/Resources/AzDoExtension.md) | Installs and uninstalls organization extensions. |
| [AzDoAuditStream](source/Examples/Resources/AzDoAuditStream.md) | Manages audit log streaming. |

## Documentation

The documentation can be found in the [AzureDevOpsDsc Wiki](https://github.com/dsccommunity/AzureDevOpsDsc/wiki).
The DSC Resource`s schema files are used to automatically update the
documentation on each PR merge.

### Examples

You can review the [Examples](/source/Examples) directory in the AzureDevOpsDsc module
for some general use scenarios for all of the resources that are in the module.

The resource examples are also available in the [AzureDevOpsDsc Wiki](https://github.com/dsccommunity/AzureDevOpsDsc/wiki).
