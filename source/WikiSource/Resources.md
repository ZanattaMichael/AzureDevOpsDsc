# DSC Resources Reference

This page provides a complete reference for all DSC resources available in **AzureDevOpsDscNative**.

## Resource Categories

### [Organization & Groups Management](#organization--groups-management)
Manage organization-level groups, memberships, and settings.

### [Project Management](#project-management)
Create and manage projects, project groups, and project-level resources.

### [Team Management](#team-management)
Manage teams and team members.

### [Repository & Git Management](#repository--git-management)
Manage Git repositories, permissions, and repository settings.

### [Permissions & Security](#permissions--security)
Manage permissions for various Azure DevOps resources and security settings.

### [Pipelines & CI/CD](#pipelines--cicd)
Configure pipelines, environments, and pipeline-related resources.

### [Service Connections & Variables](#service-connections--variables)
Manage service connections and variable groups.

### [Agents & Infrastructure](#agents--infrastructure)
Configure agent pools, queues, and deployment groups.

### [Artifacts & Package Management](#artifacts--package-management)
Manage artifact feeds and feed settings.

### [Governance & Policies](#governance--policies)
Configure branch policies and other governance settings.

### [Other Resources](#other-resources)
Miscellaneous resources for extensions, wikis, task groups, and more.

---

## Organization & Groups Management

### AzDoOrganizationGroup
Manages Azure DevOps organization-level groups.

**Key Properties:**
- `GroupName` (Key, Required) - Name of the group
- `Ensure` (Optional) - Ensure presence or absence
- `GroupDescription` (Optional) - Description of the group

[View Full Documentation](Resources/AzDoOrganizationGroup)

### AzDoGroupMember
Manages membership within Azure DevOps groups.

**Key Properties:**
- `GroupName` (Key, Required) - Name of the group
- `MemberDescriptor` (Key, Required) - Descriptor of the member to add/remove
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoGroupMember)

### AzDoGroupPermission
Manages permissions for Azure DevOps groups.

**Key Properties:**
- `GroupName` (Key, Required) - Name of the group
- `PermissionName` (Key, Required) - Name of the permission
- `Allow` (Optional) - Grant or deny permission
- `Deny` (Optional) - Explicitly deny permission

[View Full Documentation](Resources/AzDoGroupPermission)

### AzDoOrganizationSettings
Configures organization-level settings.

**Key Properties:**
- `OrganizationName` (Key, Required) - Name of the organization
- Various settings properties


### AzDoUserEntitlement
Manages user entitlements in Azure DevOps.

**Key Properties:**
- `UserEmail` (Key, Required) - Email address of the user
- `AccessLevel` (Optional) - Access level for the user
- `Ensure` (Optional) - Ensure presence or absence


---

## Project Management

### AzDoProject
Creates and manages Azure DevOps projects.

**Key Properties:**
- `ProjectName` (Key, Required) - Name of the project
- `ProjectDescription` (Optional) - Description of the project
- `SourceControlType` (Optional) - 'Git' or 'Tfvc' (default: 'Git')
- `ProcessTemplate` (Optional) - Process template ('Agile', 'Scrum', 'CMMI', 'Basic')
- `Visibility` (Optional) - 'Public' or 'Private' (default: 'Private')
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoProject)

### AzDoProjectGroup
Manages groups at the project level.

**Key Properties:**
- `ProjectName` (Key, Required) - Name of the project
- `GroupName` (Key, Required) - Name of the group
- `GroupDescription` (Optional) - Description of the group
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoProjectGroup)

### AzDoProjectServices
Manages which services are enabled for a project.

**Key Properties:**
- `ProjectName` (Key, Required) - Name of the project
- Various service properties (Pipelines, Repos, Boards, etc.)

[View Full Documentation](Resources/AzDoProjectServices)

### AzDoProjectPermission
Manages project-level permissions.

**Key Properties:**
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission
- `Allow/Deny` (Optional) - Permission setting

[View Full Documentation](Resources/AzDoProjectPermission)

### AzDoProjectSettings
Configures project-level settings.

**Key Properties:**
- `ProjectName` (Key, Required) - Name of the project
- Various settings properties


---

## Team Management

### AzDoTeam
Creates and manages teams within a project.

**Key Properties:**
- `TeamName` (Key, Required) - Name of the team
- `ProjectName` (Key, Required) - Name of the project
- `TeamDescription` (Optional) - Description of the team
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoTeam)

### AzDoTeamMember
Manages team membership.

**Key Properties:**
- `TeamName` (Key, Required) - Name of the team
- `ProjectName` (Key, Required) - Name of the project
- `MemberName` (Key, Required) - Name/email of the member
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoTeamMember)

### AzDoTeamSettings
Configures team-specific settings.

**Key Properties:**
- `TeamName` (Key, Required) - Name of the team
- `ProjectName` (Key, Required) - Name of the project
- Various settings properties


---

## Repository & Git Management

### AzDoGitRepository
Creates and manages Git repositories.

**Key Properties:**
- `RepositoryName` (Key, Required) - Name of the repository
- `ProjectName` (Key, Required) - Name of the project
- `Ensure` (Optional) - Ensure presence or absence
- `DefaultBranch` (Optional) - Default branch name

[View Full Documentation](Resources/AzDoGitRepository)

### AzDoGitPermission
Manages Git repository permissions.

**Key Properties:**
- `RepositoryName` (Key, Required) - Name of the repository
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoGitPermission)

### AzDoRepositorySettings
Configures repository-level settings.

**Key Properties:**
- `RepositoryName` (Key, Required) - Name of the repository
- `ProjectName` (Key, Required) - Name of the project
- Various settings properties


### AzDoAreaNodes
Manages area nodes (work item classification).

**Key Properties:**
- `AreaPath` (Key, Required) - Path to the area node
- `ProjectName` (Key, Required) - Name of the project
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoAreaNodes)

### AzDoIterationNodes
Manages iteration/sprint nodes.

**Key Properties:**
- `IterationPath` (Key, Required) - Path to the iteration node
- `ProjectName` (Key, Required) - Name of the project
- `StartDate` (Optional) - Start date of the iteration
- `EndDate` (Optional) - End date of the iteration

[View Full Documentation](Resources/AzDoIterationNodes)

---

## Permissions & Security

### AzDoAreaPermission
Manages permissions for area nodes.

**Key Properties:**
- `AreaPath` (Key, Required) - Path to the area
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoAreaPermission)

### AzDoIterationPermission
Manages permissions for iteration nodes.

**Key Properties:**
- `IterationPath` (Key, Required) - Path to the iteration
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoIterationPermission)

### AzDoSecurityNamespacePermission
Manages permissions at the security namespace level.

**Key Properties:**
- `SecurityNamespaceName` (Key, Required) - Name of the security namespace
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoSecurityNamespacePermission)

### AzDoBranchPolicy
Configures branch protection policies.

**Key Properties:**
- `RepositoryName` (Key, Required) - Name of the repository
- `ProjectName` (Key, Required) - Name of the project
- `BranchName` (Key, Required) - Branch to protect
- Various policy properties

[View Full Documentation](Resources/AzDoBranchPolicy)

---

## Pipelines & CI/CD

### AzDoPipeline
Creates and manages pipelines.

**Key Properties:**
- `PipelineName` (Key, Required) - Name of the pipeline
- `ProjectName` (Key, Required) - Name of the project
- `YamlPath` (Optional) - Path to pipeline YAML file
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoPipeline)

### AzDoPipelinePermission
Manages pipeline permissions.

**Key Properties:**
- `PipelineName` (Key, Required) - Name of the pipeline
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoPipelinePermission)

### AzDoPipelineEnvironment
Manages deployment environments for pipelines.

**Key Properties:**
- `EnvironmentName` (Key, Required) - Name of the environment
- `ProjectName` (Key, Required) - Name of the project
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoPipelineEnvironment)

### AzDoEnvironmentPermission
Manages environment permissions.

**Key Properties:**
- `EnvironmentName` (Key, Required) - Name of the environment
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoEnvironmentPermission)

### AzDoEnvironmentApproval
Configures environment approvals.

**Key Properties:**
- `EnvironmentName` (Key, Required) - Name of the environment
- `ProjectName` (Key, Required) - Name of the project
- `ApproverName` (Key, Required) - Name of the approver
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoEnvironmentApproval)

### AzDoPipelineSettings
Configures pipeline-level settings.

**Key Properties:**
- `ProjectName` (Key, Required) - Name of the project
- Various pipeline settings properties

[View Full Documentation](Resources/AzDoPipelineSettings)

### AzDoCheckConfiguration
Manages pipeline check configurations.

**Key Properties:**
- `CheckName` (Key, Required) - Name of the check
- `ProjectName` (Key, Required) - Name of the project
- Various check configuration properties


---

## Service Connections & Variables

### AzDoServiceConnection
Creates and manages service connections.

**Key Properties:**
- `ServiceConnectionName` (Key, Required) - Name of the service connection
- `ProjectName` (Key, Required) - Name of the project
- `ServiceConnectionType` (Required) - Type of connection
- Various connection-specific properties
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoServiceConnection)

### AzDoServiceConnectionPermission
Manages service connection permissions.

**Key Properties:**
- `ServiceConnectionName` (Key, Required) - Name of the connection
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoServiceConnectionPermission)

### AzDoVariableGroup
Creates and manages variable groups.

**Key Properties:**
- `VariableGroupName` (Key, Required) - Name of the variable group
- `ProjectName` (Key, Required) - Name of the project
- `Variables` (Optional) - Hashtable of variables
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoVariableGroup)

### AzDoVariableGroupPermission
Manages variable group permissions.

**Key Properties:**
- `VariableGroupName` (Key, Required) - Name of the variable group
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoVariableGroupPermission)

---

## Agents & Infrastructure

### AzDoAgentPool
Creates and manages agent pools.

**Key Properties:**
- `PoolName` (Key, Required) - Name of the agent pool
- `PoolDescription` (Optional) - Description of the pool
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoAgentPool)

### AzDoAgentPoolPermission
Manages agent pool permissions.

**Key Properties:**
- `PoolName` (Key, Required) - Name of the agent pool
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission

[View Full Documentation](Resources/AzDoAgentPoolPermission)

### AzDoAgentQueue
Manages agent queues (project-level queue mappings).

**Key Properties:**
- `QueueName` (Key, Required) - Name of the queue
- `ProjectName` (Key, Required) - Name of the project
- `PoolName` (Required) - Associated agent pool name

[View Full Documentation](Resources/AzDoAgentQueue)

### AzDoDeploymentGroup
Creates and manages deployment groups.

**Key Properties:**
- `DeploymentGroupName` (Key, Required) - Name of the deployment group
- `ProjectName` (Key, Required) - Name of the project
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoDeploymentGroup)

---

## Artifacts & Package Management

### AzDoArtifactFeed
Creates and manages artifact feeds.

**Key Properties:**
- `FeedName` (Key, Required) - Name of the artifact feed
- `ProjectName` (Key, Required) - Name of the project (or '@' for organization scope)
- `FeedDescription` (Optional) - Description of the feed
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoArtifactFeed)

### AzDoArtifactFeedPermission
Manages artifact feed permissions.

**Key Properties:**
- `FeedName` (Key, Required) - Name of the feed
- `ProjectName` (Key, Required) - Name of the project
- `IdentityName` (Key, Required) - Name of the identity/group
- `Role` (Optional) - Role for the identity

[View Full Documentation](Resources/AzDoArtifactFeedPermission)

### AzDoArtifactFeedSettings
Configures artifact feed settings.

**Key Properties:**
- `FeedName` (Key, Required) - Name of the feed
- `ProjectName` (Key, Required) - Name of the project
- Various feed settings properties

[View Full Documentation](Resources/AzDoArtifactFeedSettings)

### AzDoArtifactFeedView
Manages artifact feed views.

**Key Properties:**
- `ViewName` (Key, Required) - Name of the view
- `FeedName` (Key, Required) - Name of the feed
- `ProjectName` (Key, Required) - Name of the project
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoArtifactFeedView)

---

## Governance & Policies

### AzDoBranchPolicy
*(Listed under Permissions & Security above)*

Configures branch protection policies and code policies.

---

## Other Resources

### AzDoWiki
Manages project wikis.

**Key Properties:**
- `WikiName` (Key, Required) - Name of the wiki
- `ProjectName` (Key, Required) - Name of the project
- `WikiType` (Optional) - Type of wiki ('ProjectWiki', 'CodeWiki')
- `Ensure` (Optional) - Ensure presence or absence


### AzDoTaskGroup
Creates and manages task groups.

**Key Properties:**
- `TaskGroupName` (Key, Required) - Name of the task group
- `ProjectName` (Key, Required) - Name of the project
- `TaskGroupDescription` (Optional) - Description
- `Ensure` (Optional) - Ensure presence or absence


### AzDoExtension
Manages Azure DevOps extensions.

**Key Properties:**
- `ExtensionId` (Key, Required) - ID of the extension
- `ExtensionName` (Key, Required) - Name of the extension
- `Ensure` (Optional) - Ensure presence or absence


### AzDoAuditStream
Configures audit stream settings.

**Key Properties:**
- `StreamName` (Key, Required) - Name of the audit stream
- `Ensure` (Optional) - Ensure presence or absence


### AzDoNotificationSubscription
Manages notification subscriptions.

**Key Properties:**
- `SubscriptionName` (Key, Required) - Name of the subscription
- `ProjectName` (Key, Required) - Name of the project
- Various subscription settings properties
- `Ensure` (Optional) - Ensure presence or absence


### AzDoServiceHook
Creates and manages service hooks (webhooks).

**Key Properties:**
- `ServiceHookName` (Key, Required) - Name of the service hook
- `ProjectName` (Key, Required) - Name of the project
- `EventType` (Required) - Type of event to trigger on
- `TargetUrl` (Required) - URL to send webhook events to
- `Ensure` (Optional) - Ensure presence or absence


### AzDoProcess
Creates and manages custom processes.

**Key Properties:**
- `ProcessName` (Key, Required) - Name of the process
- `ProcessDescription` (Optional) - Description of the process
- `Ensure` (Optional) - Ensure presence or absence


### AzDoProcessPermission
Manages process permissions.

**Key Properties:**
- `ProcessName` (Key, Required) - Name of the process
- `IdentityName` (Key, Required) - Name of the identity/group
- `PermissionName` (Key, Required) - Name of the permission


### AzDoWIPTags
Manages Work-In-Progress (WIP) tags.

**Key Properties:**
- `TagName` (Key, Required) - Name of the WIP tag
- `ProjectName` (Key, Required) - Name of the project
- `Ensure` (Optional) - Ensure presence or absence

[View Full Documentation](Resources/AzDoWIPTags)

---

## Common Properties

Most DSC resources in AzureDevOpsDscNative support the following common properties:

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Ensure` | String | No | 'Present' or 'Absent' - desired state of the resource |
| `Credential` | PSCredential | No | Credentials for authentication (if not using other auth methods) |
| `DependsOn` | String[] | No | Resources this depends on |
| `PsDscRunAsCredential` | PSCredential | No | Credentials to run configuration as |

## Getting Started

1. Choose the resource that matches your Azure DevOps management need
2. Click the "View Full Documentation" link for detailed examples and all properties
3. Review the [Authentication Guide](Authentication) to set up proper authentication
4. Check [Examples](Examples) for real-world scenarios
5. Refer to [Best Practices](BestPractices) for optimization tips

## Need Help?

- Review resource-specific documentation for detailed property descriptions
- Check the [Examples](Examples) page for practical scenarios
- Visit the [Authentication Guide](Authentication) if you have auth issues
- See [Best Practices](BestPractices) for optimization and troubleshooting
