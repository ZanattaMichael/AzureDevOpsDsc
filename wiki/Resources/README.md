# AzureDevOpsDscNative Resources Documentation

This directory contains comprehensive documentation for all DSC resources available in the **AzureDevOpsDscNative** module.

## Organization

Resources are documented individually in markdown files, organized alphabetically by resource name:

- `AzDoProject.md` - Project management
- `AzDoGitRepository.md` - Repository management
- `AzDoTeam.md` - Team management
- `AzDoVariableGroup.md` - Variable group management
- And more...

## Resource Categories

### Organization & Groups
Manage organization-level groups, members, and permissions:
- `AzDoOrganizationGroup`
- `AzDoGroupMember`
- `AzDoGroupPermission`
- `AzDoUserEntitlement`
- `AzDoOrganizationSettings`

### Project Management
Create and configure projects:
- `AzDoProject`
- `AzDoProjectGroup`
- `AzDoProjectServices`
- `AzDoProjectPermission`
- `AzDoProjectSettings`

### Team Management
Manage teams and team members:
- `AzDoTeam`
- `AzDoTeamMember`
- `AzDoTeamSettings`

### Repository & Git
Manage Git repositories and related resources:
- `AzDoGitRepository`
- `AzDoGitPermission`
- `AzDoRepositorySettings`
- `AzDoAreaNodes`
- `AzDoIterationNodes`

### Permissions & Security
Fine-grained permission management:
- `AzDoAreaPermission`
- `AzDoIterationPermission`
- `AzDoSecurityNamespacePermission`
- `AzDoBranchPolicy`

### Pipelines & CI/CD
Manage pipelines and deployment infrastructure:
- `AzDoPipeline`
- `AzDoPipelinePermission`
- `AzDoPipelineEnvironment`
- `AzDoEnvironmentPermission`
- `AzDoEnvironmentApproval`
- `AzDoPipelineSettings`
- `AzDoCheckConfiguration`

### Service Connections & Variables
Manage connections and variables:
- `AzDoServiceConnection`
- `AzDoServiceConnectionPermission`
- `AzDoVariableGroup`
- `AzDoVariableGroupPermission`

### Agents & Infrastructure
Manage build and deployment infrastructure:
- `AzDoAgentPool`
- `AzDoAgentPoolPermission`
- `AzDoAgentQueue`
- `AzDoDeploymentGroup`

### Artifacts & Package Management
Manage artifact feeds:
- `AzDoArtifactFeed`
- `AzDoArtifactFeedPermission`
- `AzDoArtifactFeedSettings`
- `AzDoArtifactFeedView`

### Other Resources
Additional resources:
- `AzDoWiki`
- `AzDoTaskGroup`
- `AzDoExtension`
- `AzDoAuditStream`
- `AzDoNotificationSubscription`
- `AzDoServiceHook`
- `AzDoProcess`
- `AzDoProcessPermission`
- `AzDoWIPTags`

## Resource Documentation Structure

Each resource documentation file follows this consistent structure:

### 1. **Description**
High-level overview of what the resource does and its primary use cases.

### 2. **Syntax**
PowerShell DSC resource syntax showing:
- Key properties (required)
- Optional properties
- Common properties available to all resources

### 3. **Properties**
Detailed description of each property:
- Data types
- Valid values
- Default values (if applicable)
- Constraints and requirements

### 4. **Return Values**
Properties returned by the resource's `Get` method.

### 5. **Examples**
Practical examples showing:
- Basic usage
- Advanced scenarios
- Using Invoke-DscResource
- Configuration Data approaches
- Real-world patterns

### 6. **Important Notes**
Special considerations including:
- Immutable properties
- Prerequisites
- Naming conventions
- Permissions required
- Scope and organization

### 7. **Troubleshooting**
Common issues and solutions with code examples.

### 8. **Related Resources**
Links to documentation for related resources.

## Finding Resources

### By Name
Resources follow Azure DevOps naming conventions. Most resources start with `AzDo` (Azure DevOps):

- `AzDoProject` - Projects
- `AzDoTeam` - Teams
- `AzDoGit*` - Git-related
- `AzDoPipeline*` - Pipeline-related
- `AzDoServiceConnection` - Service connections
- `AzDoVariableGroup` - Variable groups
- etc.

### By Function
Look for resources related to your task:

**Need to manage projects?**
- `AzDoProject` - Create/configure projects
- `AzDoProjectGroup` - Project groups
- `AzDoProjectServices` - Project services
- `AzDoProjectPermission` - Project permissions

**Need to configure pipelines?**
- `AzDoPipeline` - Create pipelines
- `AzDoPipelineEnvironment` - Pipeline environments
- `AzDoPipelineSettings` - Pipeline settings
- `AzDoPipelinePermission` - Pipeline permissions

**Need to manage teams and people?**
- `AzDoTeam` - Create teams
- `AzDoTeamMember` - Add team members
- `AzDoTeamSettings` - Team settings
- `AzDoGroupMember` - Group membership

## Using the Documentation

### Quick Start
1. Find the resource you need (see "Finding Resources" above)
2. Open the corresponding `.md` file
3. Review the **Syntax** and **Properties** sections
4. Check the **Examples** for typical use cases
5. Note any **Important Notes** or requirements

### Detailed Understanding
For deeper understanding:
1. Read the **Description** to understand the resource's role
2. Study the **Properties** section for configuration options
3. Review multiple **Examples** to see different scenarios
4. Check **Related Resources** for integrated workflows
5. Consult **Troubleshooting** for common issues

### Implementation
When implementing a solution:
1. Review relevant **Examples**
2. Understand **Important Notes** and prerequisites
3. Note dependencies between resources (use `DependsOn`)
4. Check **Troubleshooting** for potential issues
5. Test in a non-production environment first

## Common Resource Patterns

### All resources support:
- **Ensure** - 'Present' or 'Absent' for desired state
- **DependsOn** - Specify dependencies on other resources
- **PsDscRunAsCredential** - Run under specific credential

### Key vs. Optional Properties
- **Key** properties uniquely identify a resource
- **Optional** properties configure the resource
- **Ensure** is optional (defaults to 'Present')

### Dependency Management
```powershell
# Always use DependsOn for resource ordering
AzDoGitRepository 'MyRepo' {
    ProjectName = 'MyProject'
    RepositoryName = 'MyRepository'
    DependsOn = '[AzDoProject]MyProject'  # Wait for project first
}
```

## Contributing Resource Documentation

### Adding New Resource Documentation

1. **Copy the template**:
   ```bash
   cp RESOURCE_TEMPLATE.md AzDoNewResource.md
   ```

2. **Replace placeholders**:
   - `[ResourceName]` → actual resource name
   - `[Type]` → property types
   - `[Description]` → detailed descriptions

3. **Complete each section**:
   - Update Syntax with actual properties
   - Document all properties thoroughly
   - Provide 4-6 practical examples
   - Add troubleshooting tips

4. **Verify links**:
   - Check all cross-references work
   - Verify related resources exist
   - Update README if needed

5. **Format consistently**:
   - Use standard markdown
   - Keep code examples valid
   - Use consistent formatting

### Content Guidelines

**Descriptions:**
- Clear, concise explanation of purpose
- What problems it solves
- Who should use it

**Examples:**
- Show common use cases
- Progress from simple to complex
- Include error-handling where relevant
- Use realistic values

**Troubleshooting:**
- List common issues first
- Explain root causes
- Provide solutions with code
- Reference related resources

**Important Notes:**
- Immutable properties and constraints
- Performance considerations
- Security implications
- Permissions required

## Quick Reference

### Resource Command Syntax
```powershell
# DSC Configuration approach
Configuration MyConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    Node localhost {
        AzDoResource 'Name' {
            Property1 = 'value1'
            Ensure = 'Present'
        }
    }
}

# Invoke-DscResource approach
$properties = @{ Property1 = 'value1' }
Invoke-DscResource -Name 'AzDoResource' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

### Common Property Values
```powershell
# Ensure values
Ensure = 'Present'  # Resource should exist
Ensure = 'Absent'   # Resource should not exist

# Process Templates
ProcessTemplate = 'Agile'      # Agile process
ProcessTemplate = 'Scrum'      # Scrum process
ProcessTemplate = 'CMMI'       # CMMI process
ProcessTemplate = 'Basic'      # Basic process

# Source Control Types
SourceControlType = 'Git'      # Git version control
SourceControlType = 'Tfvc'     # Team Foundation Version Control

# Visibility
Visibility = 'Private'         # Private project
Visibility = 'Public'          # Public project
```

## Resource Count

AzureDevOpsDscNative includes **50+ DSC resources** covering:
- 5 Organization & Group resources
- 5 Project resources
- 3 Team resources
- 5 Repository & Git resources
- 4 Permission resources
- 8 Pipeline & CI/CD resources
- 4 Service Connection & Variable resources
- 4 Agent & Infrastructure resources
- 4 Artifact resources
- 9 Other specialized resources

## Additional Help

- **Main Wiki**: [Home](../Home.md)
- **Resource List**: [Resources](../Resources.md)
- **Authentication**: [Authentication Guide](../Authentication.md)
- **Best Practices**: [Best Practices](../BestPractices.md)
- **Examples**: [Examples](../Examples.md)

## Template for New Resources

If a resource isn't yet documented, use [RESOURCE_TEMPLATE.md](RESOURCE_TEMPLATE.md) as a starting point.

## Questions?

- Check the **Troubleshooting** section in the resource documentation
- Review the **Related Resources** section
- Check [Best Practices](../BestPractices.md) for patterns and recommendations
- Review [Examples](../Examples.md) for real-world scenarios
