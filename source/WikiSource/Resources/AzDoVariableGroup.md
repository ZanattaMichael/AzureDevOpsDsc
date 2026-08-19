# AzDoVariableGroup Resource

## Description

The `AzDoVariableGroup` DSC resource is used to create and manage variable groups in Azure DevOps. Variable groups allow you to centralize and reuse variables across pipelines and environments, making configuration management easier and more maintainable.

## Syntax

```powershell
AzDoVariableGroup [string] #ResourceName
{
    VariableGroupName = [String] $VariableGroupName
    ProjectName = [String] $ProjectName
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ Variables = [Hashtable] $Variables ]
    [ KeyVaultName = [String] $KeyVaultName ]
    [ ServiceConnectionName = [String] $ServiceConnectionName ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **VariableGroupName** [String] - The name of the variable group. Must be unique within the project.

- **ProjectName** [String] - The name of the project that will contain this variable group.

### Optional Properties

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Variable group should exist
  - `'Absent'` - Variable group should be removed

- **Variables** [Hashtable] - A hashtable containing the variables to store in the group. Example: `@{ 'Var1' = 'Value1'; 'Var2' = 'Value2' }`

- **KeyVaultName** [String] - Optional. Name of Azure Key Vault to link for secret variables.

- **ServiceConnectionName** [String] - Optional. Name of the service connection to use for Key Vault integration.

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Typically depends on the project existing first.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **VariableGroupName** - The name of the variable group
- **ProjectName** - The project containing the variable group
- **Ensure** - Current state ('Present' or 'Absent')
- **VariableGroupId** - The unique identifier of the variable group
- **Variables** - The variables contained in the group
- **KeyVaultName** - Associated Key Vault (if linked)
- **ServiceConnectionName** - Associated service connection (if linked)

## Examples

### Example 1: Create a Basic Variable Group

```powershell
Configuration CreateBasicVariableGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # First create the project
        AzDoProject 'MyProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Create variable group
        AzDoVariableGroup 'AppSettings' {
            Ensure              = 'Present'
            VariableGroupName   = 'App Settings'
            ProjectName         = 'MyProject'
            Variables           = @{
                'Environment'       = 'Production'
                'LogLevel'          = 'Information'
                'MaxConnections'    = '100'
                'Timeout'           = '30'
            }
            DependsOn           = '[AzDoProject]MyProject'
        }
    }
}

CreateBasicVariableGroup
Start-DscConfiguration -Path ./CreateBasicVariableGroup -Wait -Verbose
```

### Example 2: Create Multiple Variable Groups for Different Environments

```powershell
Configuration EnvironmentVariableGroups {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'PipelineProject' {
            Ensure              = 'Present'
            ProjectName         = 'PipelineProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Development variables
        AzDoVariableGroup 'DevVariables' {
            Ensure              = 'Present'
            VariableGroupName   = 'Dev Variables'
            ProjectName         = 'PipelineProject'
            Variables           = @{
                'Environment'       = 'Development'
                'ApiEndpoint'       = 'https://dev-api.company.com'
                'DatabaseServer'    = 'dev-db.company.com'
                'LogLevel'          = 'Debug'
            }
            DependsOn           = '[AzDoProject]PipelineProject'
        }
        
        # Staging variables
        AzDoVariableGroup 'StagingVariables' {
            Ensure              = 'Present'
            VariableGroupName   = 'Staging Variables'
            ProjectName         = 'PipelineProject'
            Variables           = @{
                'Environment'       = 'Staging'
                'ApiEndpoint'       = 'https://staging-api.company.com'
                'DatabaseServer'    = 'staging-db.company.com'
                'LogLevel'          = 'Information'
            }
            DependsOn           = '[AzDoProject]PipelineProject'
        }
        
        # Production variables
        AzDoVariableGroup 'ProdVariables' {
            Ensure              = 'Present'
            VariableGroupName   = 'Prod Variables'
            ProjectName         = 'PipelineProject'
            Variables           = @{
                'Environment'       = 'Production'
                'ApiEndpoint'       = 'https://api.company.com'
                'DatabaseServer'    = 'prod-db.company.com'
                'LogLevel'          = 'Warning'
            }
            DependsOn           = '[AzDoProject]PipelineProject'
        }
    }
}

EnvironmentVariableGroups
Start-DscConfiguration -Path ./EnvironmentVariableGroups -Wait -Verbose
```

### Example 3: Create Variable Group with Key Vault Integration

```powershell
Configuration VariableGroupWithKeyVault {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'SecureProject' {
            Ensure              = 'Present'
            ProjectName         = 'SecureProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Create service connection for Key Vault
        AzDoServiceConnection 'KeyVaultConnection' {
            Ensure                      = 'Present'
            ServiceConnectionName       = 'Azure KeyVault'
            ProjectName                 = 'SecureProject'
            ServiceConnectionType       = 'AzureResourceManager'
            SubscriptionId              = 'your-subscription-id'
            SubscriptionName            = 'Your Subscription'
            AuthenticationMethod        = 'ServicePrincipal'
            ServicePrincipalId          = 'your-sp-id'
            ServicePrincipalKey         = 'your-sp-secret'
            TenantId                    = 'your-tenant-id'
            DependsOn                   = '[AzDoProject]SecureProject'
        }
        
        # Create variable group linked to Key Vault
        AzDoVariableGroup 'SecureVariables' {
            Ensure                  = 'Present'
            VariableGroupName       = 'Secure Variables'
            ProjectName             = 'SecureProject'
            KeyVaultName            = 'company-keyvault'
            ServiceConnectionName   = 'Azure KeyVault'
            Variables               = @{
                'StorageAccountKey'     = 'storage-account-key-secret'
                'DatabasePassword'      = 'db-password-secret'
                'ApiToken'              = 'api-token-secret'
            }
            DependsOn               = '[AzDoServiceConnection]KeyVaultConnection'
        }
    }
}

VariableGroupWithKeyVault
Start-DscConfiguration -Path ./VariableGroupWithKeyVault -Wait -Verbose
```

### Example 4: Get Variable Group Information

```powershell
# Retrieve variable group information
$properties = @{
    VariableGroupName = 'App Settings'
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoVariableGroup' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

Write-Host "Variable Group: $($result.VariableGroupName)"
Write-Host "ID: $($result.VariableGroupId)"
Write-Host "Variables: $(($result.Variables | ConvertTo-Json))"
```

### Example 5: Update Variable Group

```powershell
Configuration UpdateVariableGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Update existing variable group with new values
        AzDoVariableGroup 'UpdateAppSettings' {
            Ensure              = 'Present'
            VariableGroupName   = 'App Settings'
            ProjectName         = 'MyProject'
            Variables           = @{
                'Environment'       = 'Production'
                'LogLevel'          = 'Error'          # Changed from Information
                'MaxConnections'    = '200'            # Changed from 100
                'NewSetting'        = 'NewValue'       # Added new variable
            }
        }
    }
}

UpdateVariableGroup
Start-DscConfiguration -Path ./UpdateVariableGroup -Wait -Verbose
```

### Example 6: Remove Variable Group

```powershell
Configuration RemoveVariableGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoVariableGroup 'RemoveOldGroup' {
            Ensure              = 'Absent'
            VariableGroupName   = 'Old Settings'
            ProjectName         = 'MyProject'
        }
    }
}

RemoveVariableGroup
Start-DscConfiguration -Path ./RemoveVariableGroup -Wait -Verbose
```

### Example 7: Using Configuration Data

```powershell
# VariableGroupsConfig.psd1
@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            ProjectName = 'MyProject'
            VariableGroups = @(
                @{
                    Name = 'Build Settings'
                    Variables = @{
                        'BuildConfiguration' = 'Release'
                        'BuildPlatform' = 'Any CPU'
                    }
                },
                @{
                    Name = 'Test Settings'
                    Variables = @{
                        'TestFramework' = 'NUnit'
                        'CodeCoverage' = '80'
                    }
                }
            )
        }
    )
}

# Configuration.ps1
Configuration CreateVariableGroupsFromData {
    param([hashtable]$ConfigurationData)
    
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node $AllNodes.NodeName {
        foreach ($varGroup in $Node.VariableGroups) {
            AzDoVariableGroup "VarGroup_$($varGroup.Name)" {
                Ensure              = 'Present'
                VariableGroupName   = $varGroup.Name
                ProjectName         = $Node.ProjectName
                Variables           = $varGroup.Variables
            }
        }
    }
}

$data = Import-PowerShellDataFile -Path VariableGroupsConfig.psd1
CreateVariableGroupsFromData -ConfigurationData $data
```

## Important Notes

### Variable Naming Conventions

- Variable names should be descriptive and follow your organization's naming standards
- Use PascalCase or UPPER_SNAKE_CASE for consistency
- Avoid special characters except underscores

### Key Vault Integration

When linking to Key Vault:
- The service connection must have appropriate permissions
- Secrets stored in Key Vault will be masked in pipeline logs
- You can mix regular and secret variables

### Variable Scope

- Variables in a variable group can be used across multiple pipelines
- Project-level variable groups are accessible to all pipelines in that project
- Organization-level variable groups (using '@' as project name) are accessible organization-wide

### Permissions

To manage variable groups, ensure you have:
- Project-level administrator permissions, or
- Specific permissions for "Administer variable groups"

## Troubleshooting

### Issue: "Project Not Found"

**Cause**: The specified project doesn't exist

**Solution**:
```powershell
# Ensure the project is created first
DependsOn = '[AzDoProject]MyProject'
```

### Issue: "Variable Group Already Exists"

**Cause**: A variable group with the same name already exists

**Solution**:
- Use a unique variable group name
- Or update the existing group instead of creating a new one

### Issue: "Cannot Link to Key Vault"

**Cause**: Service connection doesn't have permissions to Key Vault

**Solution**:
- Verify the service connection exists
- Ensure it has "Get" and "List" permissions on Key Vault secrets
- Check that Key Vault access policies allow the service principal

### Issue: "Variable Not Available in Pipeline"

**Cause**: Variable group not linked to pipeline or permissions issue

**Solution**:
- Verify the variable group is in the same project as the pipeline
- Check pipeline YAML includes the variable group
- Verify user has read permissions on the variable group

## Related Resources

- [AzDoProject](AzDoProject) - Create and manage projects
- [AzDoVariableGroupPermission](../Resources/AzDoVariableGroupPermission) - Manage variable group permissions
- [AzDoServiceConnection](../Resources/AzDoServiceConnection) - Create service connections
- [AzDoPipeline](../Resources/AzDoPipeline) - Create and manage pipelines

## See Also

- [Azure DevOps Variable Groups Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [AzureDevOpsDscNative Home](../Home)
