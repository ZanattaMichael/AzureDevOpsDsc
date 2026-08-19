# Troubleshooting Guide

This guide provides solutions to common issues encountered when using AzureDevOpsDscNative.

## Table of Contents

1. [Authentication Issues](#authentication-issues)
2. [Resource Creation Issues](#resource-creation-issues)
3. [Permission Issues](#permission-issues)
4. [Configuration Issues](#configuration-issues)
5. [Performance Issues](#performance-issues)
6. [General DSC Issues](#general-dsc-issues)

## Authentication Issues

### Issue: "Authentication Failed"

**Symptoms:**
- Error: `Unable to authenticate with Azure DevOps`
- Resource creation fails at authentication step
- Tests fail with authentication error

**Common Causes:**
- Incorrect credentials or token
- Expired token or credentials
- Insufficient permissions
- Wrong organization name

**Solutions:**

1. **Verify credentials:**
   ```powershell
   # Test PAT connectivity
   $pat = 'your-pat-token'
   $headers = @{
       Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
   }
   $response = Invoke-RestMethod -Uri 'https://dev.azure.com/YourOrg/_apis/projects' -Headers $headers
   Write-Host $response.value.Count "projects found"
   ```

2. **Check token expiration:**
   ```powershell
   # Check when PAT expires in Azure DevOps portal
   # Create new token if expired
   ```

3. **Verify permissions:**
   - User should be in appropriate groups
   - PAT should have required scopes
   - For service principals, check role assignments

4. **Confirm organization name:**
   ```powershell
   # Use exact organization name from URL
   # https://dev.azure.com/YourOrgName
   ```

### Issue: "Insufficient Permissions"

**Symptoms:**
- Error: `Access denied` or `Insufficient permissions`
- Some operations succeed, others fail
- Different errors for different resources

**Solutions:**

1. **Check group membership:**
   ```powershell
   # Verify user is in Project Collection Administrators for org-level operations
   # Verify user is in Project Administrators for project-level operations
   ```

2. **Verify PAT scopes:**
   ```powershell
   # Scopes needed (in order of commonality):
   # - Project & Team
   # - Build
   # - Packaging
   # - Release
   # - Service Connections
   # - User Profile
   ```

3. **Check service principal:**
   ```powershell
   # For service principals:
   # 1. Add to appropriate groups in Azure DevOps
   # 2. Assign Azure RBAC roles if using Managed Identity
   # 3. Verify certificate is properly configured
   ```

4. **Review audit logs:**
   ```powershell
   # Check Azure DevOps audit logs for denied operations
   # Review Azure activity logs for ARM operations
   ```

### Issue: "Token Expired"

**Symptoms:**
- Worked previously, now fails
- Error appears after extended use
- Intermittent failures

**Solutions:**

1. **Create new PAT:**
   - Go to Azure DevOps > User Settings > Personal access tokens
   - Create new token with same scopes
   - Update configuration with new token

2. **Check token expiration:**
   ```powershell
   # Check PAT expiration date when creating
   # Default: 1 year, can extend to custom date
   ```

3. **Implement token rotation:**
   - Create new token before expiration
   - Update configuration gradually
   - Monitor for authentication failures

## Resource Creation Issues

### Issue: "Resource Not Found"

**Symptoms:**
- Error: `Resource does not exist` or `Not found`
- Get method returns null
- Test method returns false

**Common Causes:**
- Resource hasn't been created yet
- Typo in resource name
- Resource is in different project or scope
- Resource was deleted

**Solutions:**

1. **Verify resource exists:**
   ```powershell
   # Use Azure DevOps UI to confirm resource exists
   # Check correct project/organization
   ```

2. **Check naming:**
   ```powershell
   # Names are case-insensitive for matching
   # But case-sensitive for display
   # Verify exact spelling
   ```

3. **Ensure dependencies are created first:**
   ```powershell
   # Check DependsOn includes required resources
   DependsOn = '[AzDoProject]MyProject'
   ```

4. **Verify resource type:**
   ```powershell
   # Confirm using correct resource name
   # AzDoProject (not AzDoProjects)
   # AzDoTeam (not AzDoTeams)
   ```

### Issue: "Resource Already Exists"

**Symptoms:**
- Error: `Resource already exists`
- Cannot create resource with same name
- Name conflicts with existing resource

**Solutions:**

1. **Use unique name:**
   ```powershell
   # Add suffix or prefix to make unique
   ProjectName = 'MyProject-v2'
   ```

2. **Update existing resource:**
   ```powershell
   # Instead of creating new, update existing
   Ensure = 'Present'  # Will update if exists
   ```

3. **Remove existing resource first:**
   ```powershell
   # Create removal configuration
   AzDoProject 'RemoveOld' {
       Ensure = 'Absent'
       ProjectName = 'OldName'
   }
   ```

### Issue: "Cannot Create Resource Due to Constraints"

**Symptoms:**
- Error: `Invalid property value`
- Error: `Constraint violation`
- Error: `Cannot modify immutable property`

**Solutions:**

1. **Check immutable properties:**
   ```powershell
   # Cannot change after creation:
   # - SourceControlType (Git vs Tfvc)
   # - ProcessTemplate (Agile, Scrum, etc.)
   # - Repository name (some cases)
   # Must delete and recreate if needed
   ```

2. **Verify property values:**
   ```powershell
   # Check valid values
   ProcessTemplate = 'Agile'  # or 'Scrum', 'CMMI', 'Basic'
   SourceControlType = 'Git'  # or 'Tfvc'
   Visibility = 'Private'     # or 'Public'
   ```

3. **Check naming conventions:**
   ```powershell
   # Avoid special characters
   # Use alphanumeric + spaces, hyphens, underscores
   # Keep names reasonable length (< 255 chars)
   ```

## Permission Issues

### Issue: "Cannot Assign Permission"

**Symptoms:**
- Error: `Failed to assign permission`
- Permission appears not to take effect
- Different users see different permissions

**Solutions:**

1. **Verify group exists:**
   ```powershell
   # Ensure group is created before assigning permissions
   DependsOn = '[AzDoOrganizationGroup]GroupName'
   ```

2. **Check permission name:**
   ```powershell
   # Use exact permission name
   PermissionName = 'Create Project'  # Case matters
   ```

3. **Verify scope:**
   ```powershell
   # Organization-level: omit ProjectName
   # Project-level: include ProjectName
   # Namespace-level: use appropriate namespace
   ```

4. **Check allow/deny:**
   ```powershell
   # Deny takes precedence over Allow
   # Inherited permissions may override
   # Check parent group permissions
   ```

### Issue: "Permission Not Taking Effect"

**Symptoms:**
- Permission set but user still denied access
- Test shows permission exists but doesn't work
- Different behavior than expected

**Solutions:**

1. **Check inheritance:**
   ```powershell
   # Inherited permissions may be overridden
   # Check parent groups and scopes
   # May need to explicitly set instead of inherit
   ```

2. **Verify user assignment:**
   ```powershell
   # Ensure user is actually in the group
   # Use AzDoGroupMember to add to group
   # Check group membership in UI
   ```

3. **Wait for cache refresh:**
   ```powershell
   # Permissions cache may take 5-10 minutes
   # Try accessing resource after delay
   # Clear browser cache if using UI
   ```

4. **Check for conflicting denies:**
   ```powershell
   # Explicit deny overrides allow
   # Check all parent groups and scopes
   # Remove deny if incorrectly set
   ```

## Configuration Issues

### Issue: "Configuration Won't Apply"

**Symptoms:**
- Configuration runs but makes no changes
- Test method always returns true
- Changes don't persist

**Solutions:**

1. **Check Ensure property:**
   ```powershell
   # Ensure = 'Present' by default
   # If missing, configuration may do nothing
   Ensure = 'Present'
   ```

2. **Enable verbose logging:**
   ```powershell
   Start-DscConfiguration -Path ./Config -Wait -Verbose -Force
   ```

3. **Check DSC logs:**
   ```powershell
   # View DSC event log
   Get-WinEvent -LogName 'DSC/Operational' | 
       Where-Object Message -match 'Error' | 
       Select-Object TimeCreated, Message
   ```

4. **Verify authentication:**
   ```powershell
   # Ensure auth is properly set
   # Check token/credentials are valid
   # Verify access to required resources
   ```

### Issue: "Properties Not Updating"

**Symptoms:**
- Some properties change, others don't
- Test method indicates resource matches
- Manual changes revert

**Solutions:**

1. **Check property support:**
   ```powershell
   # Some properties may be read-only
   # SourceControlType cannot be changed after creation
   # May need to delete and recreate
   ```

2. **Use Set method explicitly:**
   ```powershell
   $properties = @{
       ProjectName = 'MyProject'
       ProjectDescription = 'New description'
   }
   Invoke-DscResource -Name 'AzDoProject' `
       -Method Set `
       -Property $properties
   ```

3. **Force reapplication:**
   ```powershell
   # Remove LCM cache
   Remove-Item C:\Windows\System32\config\systemprofile\AppData\Local\`
       dsc\configuration -Recurse -Force
   Start-DscConfiguration -Path ./Config -Force -Wait -Verbose
   ```

## Performance Issues

### Issue: "Configuration Runs Very Slowly"

**Symptoms:**
- Configuration takes unusually long time
- API calls time out
- Memory usage increases

**Solutions:**

1. **Batch similar operations:**
   ```powershell
   # Create multiple resources of same type together
   foreach ($project in $projectList) {
       AzDoProject "Project_$($project.Name)" {
           ProjectName = $project.Name
           # ...
       }
   }
   ```

2. **Reduce API calls:**
   ```powershell
   # Combine operations where possible
   # Avoid redundant Get operations
   # Cache organizational data
   ```

3. **Use parallel execution:**
   ```powershell
   # Independent resources can run in parallel
   # DSC automatically parallelizes when possible
   # Ensure proper DependsOn for ordering
   ```

4. **Increase timeouts:**
   ```powershell
   # Some operations may need more time
   # Check Azure DevOps load
   # Consider throttling rate limits
   ```

### Issue: "Rate Limiting / Throttling"

**Symptoms:**
- Error: `Rate limit exceeded`
- Error: `Too many requests`
- API calls start failing

**Solutions:**

1. **Reduce concurrency:**
   ```powershell
   # Azure DevOps has API rate limits
   # Add delays between operations
   # Use sequential instead of parallel
   ```

2. **Implement backoff:**
   ```powershell
   # Wait before retrying failed operations
   # Start small (1 second), exponential backoff
   # Max reasonable wait (1-5 minutes)
   ```

3. **Request quota increase:**
   ```powershell
   # Contact Microsoft for higher limits
   # Enterprise agreements may have higher limits
   # Monitor usage patterns
   ```

## General DSC Issues

### Issue: "DSC Configuration Fails"

**Symptoms:**
- Configuration fails to run
- Compilation errors
- Resource not found

**Solutions:**

1. **Verify module is imported:**
   ```powershell
   Import-DscResource -ModuleName 'AzureDevOpsDscNative'
   
   # Check module is installed
   Get-Module AzureDevOpsDscNative -ListAvailable
   ```

2. **Check PowerShell version:**
   ```powershell
   # Requires PowerShell 7.0+
   $PSVersionTable.PSVersion
   ```

3. **Clear DSC cache:**
   ```powershell
   # Remove cached configurations
   Remove-Item C:\Windows\System32\config\systemprofile\`
       AppData\Local\dsc\configuration -Recurse -Force
   ```

4. **Review syntax:**
   ```powershell
   # Check configuration syntax
   # Verify all properties are valid
   # Check for typos in resource names
   ```

### Issue: "Get/Test/Set Method Fails"

**Symptoms:**
- Get returns error
- Test method throws exception
- Set method fails silently

**Solutions:**

1. **Enable debug output:**
   ```powershell
   $DebugPreference = 'Continue'
   Invoke-DscResource -Name 'AzDoProject' -Method Get -Property @{ProjectName='Test'}
   ```

2. **Check prerequisites:**
   ```powershell
   # Verify all dependencies are met
   # Check required modules are installed
   # Ensure authentication is working
   ```

3. **Test with Invoke-DscResource:**
   ```powershell
   # Test individual resource
   Invoke-DscResource -Name 'AzDoProject' `
       -Method Test `
       -Property @{ProjectName='Test'; Ensure='Present'} `
       -ModuleName 'AzureDevOpsDscNative'
   ```

## Getting More Help

If you can't find solution here:

1. **Check resource documentation**: See [Resources](Resources) for specific resource help
2. **Review examples**: Look for similar scenario in [Examples](Examples)
3. **Check Best Practices**: See [Best Practices](BestPractices) for patterns
4. **Enable logging**: Use verbose/debug output for more details
5. **Check Azure DevOps status**: Verify service isn't having issues
6. **Report issue**: File issue on GitHub with configuration and error details

## Quick Reference

**Common Errors:**
- `404 Not Found` - Resource doesn't exist
- `403 Forbidden` - Insufficient permissions
- `401 Unauthorized` - Authentication failed
- `409 Conflict` - Resource name conflict
- `400 Bad Request` - Invalid property value
- `429 Too Many Requests` - Rate limit exceeded
- `500 Server Error` - Azure DevOps service issue

**Quick Fixes:**
1. Check authentication first
2. Verify resource exists
3. Confirm permissions
4. Check property values
5. Review dependencies
6. Enable verbose logging
7. Check Azure DevOps status
8. Try again after delay
