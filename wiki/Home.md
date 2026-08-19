# Welcome to the AzureDevOpsDscNative Wiki

<sup>*AzureDevOpsDscNative - Native DSC v3 Support for Azure DevOps*</sup>

Welcome to the comprehensive documentation for **AzureDevOpsDscNative**, a PowerShell Desired State Configuration (DSC) module for managing and configuring Azure DevOps organizations, projects, and resources.

> **Note:** This is a native DSC v3 module where every resource is discoverable and invokable by `dsc.exe` via the `Microsoft.Adapter/PowerShell` adapter, using generated adapted resource manifests. No wrapper resources required.

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
- **Automation**: Automate complex Azure DevOps configurations using DSC

## Quick Start

### Installation

Install **AzureDevOpsDscNative** from the PowerShell Gallery:

```powershell
Install-Module -Name AzureDevOpsDscNative -Repository PSGallery
```

Or download from [PowerShell Gallery](https://www.powershellgallery.com/packages/AzureDevOpsDscNative)

### Verify Installation

Confirm that the module is installed and resources are available:

```powershell
Get-DscResource -Module AzureDevOpsDscNative
```

### Prerequisites

- **PowerShell 7.0 or later** - Required for this module
- **Azure DevOps Account** - Access to an Azure DevOps organization
- **Authentication Token** - Personal Access Token (PAT), Managed Identity, Service Principal, or other supported authentication methods

### Basic Usage Example

```powershell
Configuration AzureDevOpsConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyProject' {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            ProjectDescription   = 'A sample Azure DevOps project'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
    }
}

AzureDevOpsConfig
Start-DscConfiguration -Path ./AzureDevOpsConfig -Wait -Verbose
```

## Documentation Structure

### [DSC Resources](Resources.md)
Complete reference for all available DSC resources in AzureDevOpsDscNative, organized by category:
- **Organization Management** - Organization-level resources
- **Project Management** - Project and project-level resources
- **Team Management** - Teams and team settings
- **Repository Management** - Git repositories and settings
- **Permissions & Security** - Permission and security-related resources
- **Pipeline & CI/CD** - Pipeline, environment, and automation resources
- **Artifacts & NuGet** - Artifact feed management
- **Infrastructure** - Agent pools, deployment groups, and related resources
- **Governance & Policies** - Policies and branch protection
- **Settings & Configuration** - Various configuration and settings resources

### 🔐 [Permissions & ACLs](Permissions.md)
**The single starting point for permissions and ACLs.** Covers how CSS Security Namespaces, ACLs, and ACEs work in this module, a full table of every permission resource and its permission bits, identity syntax, and common pitfalls (including the slow-scan warning for Area/Iteration/Pipeline permission resources).

### 🛠️ [Dsc.PipelineRunner Configuration](LCMConfiguration.md)
How to actually apply configurations built with this module at scale using the companion **[Dsc.PipelineRunner](https://github.com/ZanattaMichael/Dsc.PipelineRunner/)** project: Datum-based configuration layering, pipeline rules, `dependsOn`/`condition`/`postExecutionScript`, and running `Invoke-AZDoLCM`.

### [Authentication Guide](Authentication.md)
Learn how to authenticate with Azure DevOps using various methods:
- Personal Access Tokens (PAT)
- Managed Identity
- Service Principal
- Certificate-based Authentication
- Azure CLI Token
- Workload Identity Federation

### [Best Practices](BestPractices.md)
Guidelines and recommendations for using AzureDevOpsDscNative effectively:
- Configuration management patterns
- Security best practices
- Performance optimization
- Error handling and troubleshooting
- Large-scale deployments

### [Examples](Examples.md)
Practical examples and scenarios:
- Setting up a new project with all resources
- Configuring security and permissions
- Setting up CI/CD pipelines
- Artifact feed configuration
- Team structure automation

## Available Resources

AzureDevOpsDscNative includes **49 DSC resources** covering:

### Organization & Groups
- `AzDoOrganizationGroup` - Manage organization-level groups
- `AzDoGroupMember` - Manage group membership
- `AzDoGroupPermission` - Manage group permissions
- `AzDoOrganizationSettings` - Configure organization settings
- `AzDoUserEntitlement` - Manage user entitlements

### Projects
- `AzDoProject` - Create and manage projects
- `AzDoProjectGroup` - Manage project groups
- `AzDoProjectServices` - Manage project services
- `AzDoProjectPermission` - Manage project permissions

### Teams
- `AzDoTeam` - Create and manage teams
- `AzDoTeamMember` - Manage team membership
- `AzDoTeamSettings` - Configure team settings

### Repository & Git
- `AzDoGitRepository` - Create and manage Git repositories
- `AzDoGitPermission` - Manage repository permissions
- `AzDoRepositorySettings` - Configure repository settings
- `AzDoAreaNodes` - Manage area nodes
- `AzDoIterationNodes` - Manage iteration nodes

### Permissions & Security
- `AzDoAreaPermission` - Manage area permissions
- `AzDoIterationPermission` - Manage iteration permissions
- `AzDoSecurityNamespacePermission` - Manage security namespace permissions
- `AzDoBranchPolicy` - Configure branch policies

### Pipelines & CI/CD
- `AzDoPipeline` - Create and manage pipelines
- `AzDoPipelinePermission` - Manage pipeline permissions
- `AzDoPipelineEnvironment` - Manage pipeline environments
- `AzDoEnvironmentPermission` - Manage environment permissions
- `AzDoEnvironmentApproval` - Configure environment approvals
- `AzDoPipelineSettings` - Configure pipeline settings
- `AzDoCheckConfiguration` - Manage pipeline checks

### Service Connections & Variables
- `AzDoServiceConnection` - Create and manage service connections
- `AzDoServiceConnectionPermission` - Manage service connection permissions
- `AzDoVariableGroup` - Create and manage variable groups
- `AzDoVariableGroupPermission` - Manage variable group permissions

### Agents & Infrastructure
- `AzDoAgentPool` - Create and manage agent pools
- `AzDoAgentPoolPermission` - Manage agent pool permissions
- `AzDoAgentQueue` - Manage agent queues
- `AzDoDeploymentGroup` - Create and manage deployment groups

### Artifacts
- `AzDoArtifactFeed` - Create and manage artifact feeds
- `AzDoArtifactFeedPermission` - Manage feed permissions
- `AzDoArtifactFeedSettings` - Configure feed settings
- `AzDoArtifactFeedView` - Manage feed views

### Other Resources
- `AzDoWiki` - Manage project wikis
- `AzDoTaskGroup` - Create and manage task groups
- `AzDoExtension` - Manage extensions
- `AzDoAuditStream` - Configure audit streams
- `AzDoNotificationSubscription` - Manage notification subscriptions
- `AzDoServiceHook` - Create and manage service hooks
- `AzDoProcess` - Create and manage custom processes
- `AzDoProcessPermission` - Manage process permissions
- `AzDoWIPTags` - Manage WIP tags

## Key Features

✅ **49 Native DSC Resources** - Cover most Azure DevOps management needs

✅ **Native DSC v3 Support** - Full compatibility with `dsc.exe` and adapted resource manifests

✅ **Multiple Authentication Methods** - PAT, Managed Identity, Service Principal, and more

✅ **Comprehensive Permissions** - Fine-grained control over all Azure DevOps security scenarios

✅ **Well-Tested** - Extensive unit and integration tests

✅ **Active Development** - Regularly updated with new features and improvements

✅ **DSC Community** - Part of the DSC Community initiative

## Getting Help

- **Documentation**: Review the resource-specific documentation in this wiki
- **Examples**: Check the Examples section for common scenarios
- **Issues**: Report issues on GitHub: [AzureDevOpsDscNative Issues](https://github.com/dsccommunity/AzureDevOpsDsc/issues)
- **Contributing**: Contributions are welcome! See [Contributing Guidelines](CONTRIBUTING.md)

## Support

This module is provided as-is under the MIT License. For commercial support, please refer to the contributing organization.

## Related Projects

- [AzureDevOpsDsc](https://github.com/dsccommunity/AzureDevOpsDsc) - Original module (PowerShell 5.1 compatible)
- [AzureDevOpsDscv3](https://github.com/mimachniak/AzureDevOpsDscv3) - Alternative DSC v3 implementation

## Change Log

See [CHANGELOG.md](CHANGELOG.md) for a complete list of changes in each version.
