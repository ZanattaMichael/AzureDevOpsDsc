# Frequently Asked Questions (FAQ)

## General Questions

### Q: What is AzureDevOpsDscNative?

A: **AzureDevOpsDscNative** is a PowerShell Desired State Configuration (DSC) module that provides 50+ native DSC resources for managing Azure DevOps. It's a separate release from the original AzureDevOpsDsc, designed specifically for DSC v3 with native support for the `dsc.exe` command-line tool.

### Q: How is AzureDevOpsDscNative different from AzureDevOpsDsc?

A:
- **AzureDevOpsDscNative**: DSC v3 native resources, works with `dsc.exe`, separate module name
- **AzureDevOpsDsc**: PowerShell 5.1+ compatible, classic DSC, original module

Choose AzureDevOpsDscNative if you need DSC v3 native support; otherwise use AzureDevOpsDsc.

### Q: What are the system requirements?

A:
- **PowerShell 7.0+** (not 5.1)
- **Windows, macOS, or Linux** (PowerShell Core)
- **Azure DevOps account** with appropriate permissions
- **Network access** to dev.azure.com or your Azure DevOps Server

### Q: How do I install the module?

A:
```powershell
Install-Module -Name AzureDevOpsDscNative -Repository PSGallery
```

Verify installation:
```powershell
Get-DscResource -Module AzureDevOpsDscNative
```

### Q: Is this for Azure DevOps Server (on-premises)?

A: The module is primarily designed for Azure DevOps Services (cloud), but may work with Azure DevOps Server (on-premises) with configuration adjustments.

## Authentication Questions

### Q: Which authentication method should I use?

A:
- **Local/Desktop**: Personal Access Token (PAT) or Azure CLI Token
- **Azure VMs/Services**: Managed Identity (recommended)
- **CI/CD Pipelines**: Service Principal or Workload Identity
- **Cross-tenant**: Service Principal
- **High security**: Certificate-based authentication

See [Authentication Guide](Authentication) for details.

### Q: Can I hardcode my credentials in the configuration?

A: **No, please don't!** Hardcoding credentials is a security risk. Instead:
- Use Azure Key Vault
- Use Windows Credential Manager
- Use PowerShell SecretStore module
- Use environment variables
- Use managed identities

### Q: How often do I need to rotate my credentials?

A: 
- **PAT tokens**: Every 90 days (recommended expiration)
- **Service Principal secrets**: Every 6-12 months
- **Certificates**: Based on certificate validity (usually 1-2 years)
- **Managed Identity**: No rotation needed (Azure handles it)

### Q: What if my authentication token expires?

A: The configuration will fail to apply. Solution:
1. Create a new token/credential
2. Update your configuration
3. Reapply the configuration
4. Test to verify it works

## Resource Questions

### Q: How many resources are available?

A: **50+ resources** covering:
- Projects and teams
- Repositories and permissions
- Pipelines and environments
- Service connections and variables
- Artifact feeds
- Agent pools and infrastructure
- Settings and configurations
- Permissions and security

See [Resources](Resources) for complete list.

### Q: Can I use resources for on-premises Azure DevOps Server?

A: Most resources should work with Azure DevOps Server (on-premises), but:
- Adjust organization URL to your server URL
- Some cloud-only features may not work
- Test thoroughly before production use

### Q: What if a resource I need doesn't exist?

A:
1. Check [Resources](Resources) - it might exist under different name
2. Check if similar resource can accomplish your goal
3. File an issue on GitHub requesting the resource
4. Consider using direct API calls via Script resource as workaround

### Q: Can I modify an existing resource?

A: Most resource properties can be updated. However:
- Some properties are **immutable** (can't be changed):
  - Project SourceControlType (Git vs Tfvc)
  - Project ProcessTemplate
  - Some repository settings
- To change immutable properties, delete and recreate the resource

## Configuration Questions

### Q: How do I structure my configurations?

A: Best practices:
```powershell
# Organize by environment
.\Config\
├── Dev\
├── Staging\
└── Production\

# Or by resource type
.\Config\
├── Projects\
├── Teams\
├── Pipelines\
└── Settings\

# Use configuration data
.\Config\
├── Configuration.ps1
├── Data\
│   ├── Dev.psd1
│   ├── Staging.psd1
│   └── Prod.psd1
└── Resources\
    ├── Projects.ps1
    └── Teams.ps1
```

### Q: How do I handle configuration drift?

A: DSC handles this automatically:
```powershell
# Reapply to fix drift
Start-DscConfiguration -Path ./Config -Wait

# Monitor for drift
Get-DscConfigurationStatus
```

### Q: Can I use the same configuration for multiple environments?

A: Yes, use configuration data files:
```powershell
Configuration Deploy {
    param([hashtable]$ConfigurationData)
    # Configuration uses $Node properties
}

$devData = Import-PowerShellDataFile ./Dev.psd1
$prodData = Import-PowerShellDataFile ./Prod.psd1

Deploy -ConfigurationData $devData
Deploy -ConfigurationData $prodData
```

## Performance Questions

### Q: Why is my configuration running slowly?

A:
- Check Azure DevOps service status
- Reduce number of resources in single configuration
- Use parallel execution where possible
- Check for rate limiting (429 errors)
- Verify network connectivity

### Q: How many resources can I configure at once?

A: Practical limit depends on:
- Azure DevOps API rate limits
- Network bandwidth
- Your system resources
- Complexity of resources

Recommended: 50-100 resources per configuration, spread across multiple runs for large deployments.

### Q: Will DSC work with slow/unstable networks?

A: It can, but:
- Increase timeout values
- Implement retry logic
- Use smaller configurations
- Monitor for partial failures
- Consider on-premises LCM servers

## Troubleshooting Questions

### Q: Why won't my configuration apply?

A: Common causes:
1. Authentication failed - check credentials
2. Resource doesn't exist - check project/group exists first
3. Insufficient permissions - check user role
4. Invalid property value - check syntax and valid values
5. Network issue - check connectivity to Azure DevOps

See [Troubleshooting Guide](Troubleshooting) for detailed solutions.

### Q: How do I debug a failed configuration?

A:
```powershell
# Enable verbose output
Start-DscConfiguration -Path ./Config -Wait -Verbose

# Check DSC event log
Get-WinEvent -LogName 'DSC/Operational' | 
    Where-Object Level -le 3 | 
    Select-Object TimeCreated, Message

# Use Invoke-DscResource for single resource
Invoke-DscResource -Name 'AzDoProject' -Method Get `
    -Property @{ProjectName='Test'} -Verbose
```

### Q: What does error "404 Not Found" mean?

A: Resource doesn't exist. Common causes:
- Wrong project/organization name
- Typo in resource name
- Resource deleted
- Insufficient permissions to view resource

### Q: What does error "403 Forbidden" mean?

A: Insufficient permissions. Solutions:
1. Check user is in correct group
2. Verify role/permissions assignment
3. Check PAT scopes
4. Verify service principal permissions

## Integration Questions

### Q: Can I use AzureDevOpsDscNative with other DSC resources?

A: Yes, it works alongside other DSC resources and modules.

### Q: Can I use it in Azure Automation?

A: Yes, Azure Automation supports PowerShell DSC with compatible PowerShell version.

### Q: Can I use it with Git for version control?

A: Yes! This is recommended:
```powershell
git init
git add *.ps1 *.psd1 *.md
git commit -m "Initial configuration"
```

### Q: Can I use it with CI/CD pipelines?

A: Yes, use in Azure Pipelines:
```yaml
- task: PowerShell@2
  inputs:
    targetType: inline
    script: |
      Install-Module AzureDevOpsDscNative
      ./Config.ps1
      Start-DscConfiguration -Path ./Config -Wait
```

## Licensing Questions

### Q: What license does AzureDevOpsDscNative use?

A: **MIT License** - free to use, modify, and distribute with attribution.

### Q: Can I use it commercially?

A: Yes, MIT license allows commercial use.

### Q: Do I need to pay for Azure DevOps access?

A: No, AzureDevOpsDsc is free. Azure DevOps has free tier and paid plans depending on usage.

## Contribution Questions

### Q: How can I contribute?

A:
1. Report bugs on GitHub issues
2. Submit pull requests with improvements
3. Help with documentation
4. Test in your environment and provide feedback

### Q: Can I add new resources?

A: Yes! See [Contributing Guidelines](CONTRIBUTING) for details.

### Q: How do I report a bug?

A: Create issue on GitHub with:
- Resource name
- Configuration code
- Error message
- Steps to reproduce
- PowerShell version
- Module version

## Support Questions

### Q: Where can I get help?

A:
1. Check this wiki for documentation
2. Review [Examples](Examples)
3. See [Troubleshooting Guide](Troubleshooting)
4. Check [Best Practices](BestPractices)
5. File issue on GitHub

### Q: Is there paid support?

A: Module itself is free with community support. For paid support, contact the DSC Community or your organization's support team.

### Q: Who maintains this project?

A: The module is maintained by the DSC Community. Contributors and maintainers volunteer their time.

## More Help

- [Home](Home) - Overview
- [Resources](Resources) - Complete resource reference
- [Examples](Examples) - Practical scenarios
- [Authentication](Authentication) - Auth methods
- [BestPractices](BestPractices) - Guidelines
- [Troubleshooting](Troubleshooting) - Problem solving
- [GitHub Issues](https://github.com/dsccommunity/AzureDevOpsDsc/issues) - Report issues
