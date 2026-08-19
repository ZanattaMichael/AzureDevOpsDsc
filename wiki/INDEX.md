# AzureDevOpsDscNative Wiki - Complete Index

Welcome to the comprehensive wiki for **AzureDevOpsDscNative**, a native DSC v3 module for managing Azure DevOps.

## 📚 Wiki Structure

The wiki is organized into several key sections to help you find what you need:

### Main Pages

| Page | Purpose | Best For |
|------|---------|----------|
| [Home](Home.md) | Overview and quick start | Getting started, module features |
| [Resources](Resources.md) | Resource reference organized by category | Finding specific resources |
| [Permissions & ACLs](Permissions.md) | Permission/ACL concepts, full bit-name reference, pitfalls | Configuring or troubleshooting any permission resource |
| [Dsc.PipelineRunner Configuration](LCMConfiguration.md) | How Dsc.PipelineRunner applies configurations at scale | Deploying with Dsc.PipelineRunner |
| [Authentication](Authentication.md) | Authentication methods and setup | Configuring authentication |
| [Best Practices](BestPractices.md) | Guidelines and recommendations | Improving implementations |
| [Examples](Examples.md) | Practical scenarios and workflows | Learning by example |

### Resource Documentation

Individual resource pages are in the [Resources/](Resources/) directory:

**Core Resources:**
- [AzDoProject](Resources/AzDoProject.md) - Create and manage projects
- [AzDoGitRepository](Resources/AzDoGitRepository.md) - Manage Git repositories
- [AzDoTeam](Resources/AzDoTeam.md) - Create and manage teams
- [AzDoVariableGroup](Resources/AzDoVariableGroup.md) - Manage variable groups

**Resource Template:**
- [RESOURCE_TEMPLATE.md](Resources/RESOURCE_TEMPLATE.md) - Template for contributing new resource docs

**Resources Directory README:**
- [Resources/README.md](Resources/README.md) - How to use and contribute to resource documentation

## 🚀 Getting Started

### I'm New to AzureDevOpsDscNative
1. Start with [Home](Home.md)
2. Read the Quick Start section
3. Review a [Simple Example](Examples.md#basic-project-setup)
4. Check [Authentication](Authentication.md) to set up credentials

### I Need to Use a Specific Resource
1. Find it in [Resources](Resources.md)
2. Open the resource's documentation page
3. Review examples and properties
4. Refer to [Best Practices](BestPractices.md) for optimization

### I'm Setting Up a Complex Environment
1. Review [Best Practices](BestPractices.md) first
2. Study relevant [Examples](Examples.md)
3. Reference individual resources as needed
4. Use configuration data files for organization

### I'm Troubleshooting an Issue
1. Check the specific resource's troubleshooting section
2. Review [Best Practices](BestPractices.md#error-handling--troubleshooting)
3. Verify [Authentication](Authentication.md) setup
4. Check related resources for dependencies

## 📖 Learning Paths

### Path 1: Basic Project Setup (30 minutes)
1. [Home - Quick Start](Home.md#quick-start)
2. [Authentication Guide](Authentication.md) - Choose your method
3. [Example: Basic Project Setup](Examples.md#basic-project-setup)
4. [AzDoProject Resource](Resources/AzDoProject.md)

### Path 2: Complete CI/CD Pipeline (1-2 hours)
1. [Best Practices](BestPractices.md) - Understand patterns
2. [Example: Pipeline and CI/CD Setup](Examples.md#pipeline-and-cicd-setup)
3. [AzDoPipeline Resource](Resources/) - (Documentation coming soon)
4. [AzDoVariableGroup Resource](Resources/AzDoVariableGroup.md)
5. [AzDoServiceConnection Resource](Resources/) - (Documentation coming soon)

### Path 3: Enterprise Deployment (2-4 hours)
1. [Best Practices - Large-Scale Deployments](BestPractices.md#large-scale-deployments)
2. [Example: Multi-Project Organization](Examples.md#multi-project-organization-setup)
3. [Best Practices - Configuration Management](BestPractices.md#configuration-management)
4. [Best Practices - Security](BestPractices.md#security-best-practices)
5. Review multiple resource pages for your specific needs

## 🔑 Key Concepts

### DSC Resources
DSC Resources are the building blocks of AzureDevOpsDscNative. Each resource manages a specific Azure DevOps entity.

**Resource Types:**
- **Ensure** - Controls desired state ('Present' or 'Absent')
- **Key Properties** - Uniquely identify a resource
- **Optional Properties** - Configure the resource
- **Dependencies** - Control execution order

### Common Patterns

**Project Setup:**
```
Create Project → Create Repositories → Configure Permissions
```

**Pipeline Setup:**
```
Create Project → Create Service Connections → Create Variable Groups → Create Pipelines
```

**Team Organization:**
```
Create Project → Create Teams → Add Team Members → Assign Permissions
```

## 📋 Available Resources

AzureDevOpsDscNative includes **50+ resources** organized in these categories:

| Category | Count | Resources |
|----------|-------|-----------|
| Organization & Groups | 5 | Groups, Members, Permissions, Settings, Entitlements |
| Project Management | 5 | Projects, Groups, Services, Permissions, Settings |
| Team Management | 3 | Teams, Members, Settings |
| Repository & Git | 5 | Repositories, Permissions, Settings, Areas, Iterations |
| Permissions & Security | 4 | Area, Iteration, Namespace, Branch Policies |
| Pipelines & CI/CD | 8 | Pipelines, Environments, Settings, Approvals, Checks |
| Service Connections | 4 | Connections, Permissions, Variables, Group Permissions |
| Agents & Infrastructure | 4 | Pools, Queues, Deployment Groups, Permissions |
| Artifacts | 4 | Feeds, Permissions, Settings, Views |
| Other | 9+ | Wikis, Task Groups, Extensions, Webhooks, etc. |

See [Resources.md](Resources.md) for complete list with descriptions.

## 🔐 Authentication

### Supported Methods
1. **Personal Access Token** (PAT) - Simple, widely used
2. **Managed Identity** - Best for Azure resources
3. **Service Principal** - CI/CD and automation
4. **Certificate-Based** - Enhanced security
5. **Azure CLI Token** - Local development
6. **Workload Identity** - Keyless CI/CD

Choose based on your scenario. [Learn more](Authentication.md)

## 🛠️ Common Tasks

### Create a New Project
1. Read [AzDoProject Resource](Resources/AzDoProject.md)
2. Follow [Example 1](Resources/AzDoProject.md#example-1-create-a-basic-agile-project)
3. Run the configuration

### Set Up Teams
1. Read [AzDoTeam Resource](Resources/AzDoTeam.md)
2. Follow [Example 1](Resources/AzDoTeam.md#example-1-create-a-single-team)
3. Use [AzDoTeamMember](Resources/) for team members

### Configure Permissions
1. Start at [Permissions & ACLs](Permissions.md) for the concepts and full bit-name reference
2. Check [Example: Permission Management](Examples.md#permission-management)
3. Open the specific permission resource's page for detailed syntax

### Set Up Pipelines
1. Review [Example: Pipeline Setup](Examples.md#pipeline-and-cicd-setup)
2. Check [Best Practices - CI/CD](BestPractices.md)
3. Reference pipeline-related resources

## 📚 Documentation Sections

### [Home Page](Home.md)
- Module overview
- Key features
- Quick start guide
- Feature summary

### [Resources](Resources.md)
- Complete resource reference
- Organized by category
- Property descriptions
- Quick links to detailed docs

### [Resource Documentation](Resources/)
- Detailed resource pages
- Comprehensive examples
- Troubleshooting guides
- Related resources

### [Authentication Guide](Authentication.md)
- Multiple auth methods
- Setup instructions
- Best practices
- Troubleshooting auth issues

### [Best Practices](BestPractices.md)
- Configuration management patterns
- Security guidelines
- Performance optimization
- Error handling
- Large-scale deployment strategies
- Testing and validation
- Maintenance and updates

### [Examples](Examples.md)
- Basic project setup
- Complete project with teams
- Git repository configuration
- Pipeline and CI/CD setup
- Permission management
- Artifact feed setup
- Multi-project organization setup
- Configuration data approaches
- Common patterns and reusable templates

## 🤝 Contributing

### Documentation Contributions

To contribute resource documentation:
1. Copy [Resources/RESOURCE_TEMPLATE.md](Resources/RESOURCE_TEMPLATE.md)
2. Name it `AzDo[ResourceName].md`
3. Fill in all sections with accurate information
4. Include 4-6 practical examples
5. Add troubleshooting section
6. Submit for review

See [Resources/README.md](Resources/README.md) for detailed guidelines.

## 🔄 Navigation

**Quick Navigation:**
- [Go to Home](Home.md)
- [View All Resources](Resources.md)
- [Authentication Help](Authentication.md)
- [Find Examples](Examples.md)
- [Best Practices Guide](BestPractices.md)

**By Topic:**
- **Getting Started**: [Home](Home.md) → [Examples](Examples.md)
- **Resources**: [Resources](Resources.md) → [Individual Pages](Resources/)
- **Implementation**: [Best Practices](BestPractices.md) → [Examples](Examples.md)
- **Problems**: [Troubleshooting](#troubleshooting-an-issue) → Resource pages

## 📊 Quick Stats

- **Total Resources**: 50+
- **Documentation Pages**: 8+ (Main pages + Resource pages)
- **Code Examples**: 30+
- **Authentication Methods**: 6
- **Resource Categories**: 10+

## ⚡ Quick Links

### Most Used Resources
- [AzDoProject](Resources/AzDoProject.md)
- [AzDoGitRepository](Resources/AzDoGitRepository.md)
- [AzDoTeam](Resources/AzDoTeam.md)
- [AzDoVariableGroup](Resources/AzDoVariableGroup.md)

### Most Viewed Pages
- [Home](Home.md)
- [Examples](Examples.md)
- [Best Practices](BestPractices.md)
- [Authentication](Authentication.md)

### Common Searches
- How do I create a project? → [AzDoProject](Resources/AzDoProject.md)
- How do I manage permissions or ACLs? → [Permissions & ACLs](Permissions.md)
- How do I set up a pipeline? → [Pipeline Example](Examples.md#pipeline-and-cicd-setup)
- How do I authenticate? → [Authentication Guide](Authentication.md)
- How do I apply configuration at scale / use Dsc.PipelineRunner? → [Dsc.PipelineRunner Configuration](LCMConfiguration.md)

## 🆘 Need Help?

1. **For specific resources** → Check that resource's page in [Resources/](Resources/)
2. **For common issues** → Review [Troubleshooting](BestPractices.md#error-handling--troubleshooting)
3. **For authentication** → See [Authentication Guide](Authentication.md)
4. **For patterns** → Check [Best Practices](BestPractices.md)
5. **For examples** → Browse [Examples](Examples.md)

## 📝 Changelog

The complete changelog is available in the GitHub repository:
- [GitHub Changelog](https://github.com/dsccommunity/AzureDevOpsDsc/blob/main/CHANGELOG.md)

## 🔗 External Resources

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/)
- [GitHub Repository](https://github.com/dsccommunity/AzureDevOpsDsc)
- [PowerShell Gallery](https://www.powershellgallery.com/packages/AzureDevOpsDscNative/)

## 📄 License

AzureDevOpsDscNative is licensed under the MIT License. See LICENSE file in the repository for details.

---

**Last Updated**: August 2025  
**Wiki Version**: 1.0  
**Module**: AzureDevOpsDscNative - Native DSC v3 Module

Ready to get started? Head to [Home](Home.md) or choose a [Learning Path](#-learning-paths) above!
