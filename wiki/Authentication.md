# Authentication Guide

AzureDevOpsDscNative supports multiple authentication methods for connecting to Azure DevOps. This guide covers all available authentication options and how to configure them.

## Supported Authentication Methods

1. **Personal Access Token (PAT)** - Most common and flexible
2. **Managed Identity** - Best for Azure resources
3. **Service Principal** - For service-to-service authentication
4. **Certificate-Based Authentication** - For secure service principals
5. **Azure CLI Token** - Use existing Azure CLI login session
6. **Workload Identity Federation** - Keyless authentication for CI/CD

## Personal Access Token (PAT)

Personal Access Tokens are the most straightforward authentication method for most scenarios.

### Creating a PAT

1. In Azure DevOps, click on your profile icon (top right)
2. Select **Personal access tokens**
3. Click **New Token**
4. Configure:
   - **Name**: Give your token a meaningful name
   - **Organization**: Select your organization
   - **Expiration**: Set expiration (30, 60, 90 days or custom)
   - **Scopes**: Select required scopes (typically "Full access" for DSC operations)
5. Click **Create**
6. Copy the token immediately (you won't see it again)

### Using PAT in DSC Configuration

```powershell
Configuration ExampleWithPAT {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Method 1: Using hashtable with token
        $authToken = @{
            PersonalAccessToken = 'your-pat-token-here'
            OrganizationName = 'your-org-name'
        }
        
        AzDoProject 'MyProject' {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            ProjectDescription   = 'Sample project'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
    }
}

AzureDevOpsConfig
Start-DscConfiguration -Path ./AzureDevOpsConfig -Wait -Verbose
```

### Best Practices for PAT

- ✅ Store PAT in secure location (Azure Key Vault, Windows Credential Manager, etc.)
- ✅ Use minimal required scopes
- ✅ Set reasonable expiration (30-90 days)
- ✅ Rotate tokens periodically
- ✅ Never commit PAT to version control
- ❌ Don't use "Full access" scope if more limited scope suffices
- ❌ Don't hardcode PAT in configuration files

## Managed Identity

Managed Identity is recommended for Azure resources, as it doesn't require managing tokens or credentials.

### Prerequisites

- Resource running in Azure (VM, App Service, Container Instance, etc.)
- Managed Identity enabled on the resource
- Appropriate permissions assigned to the identity

### Using Managed Identity

```powershell
Configuration ExampleWithManagedIdentity {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Managed Identity authentication is automatically discovered
        # No explicit credential configuration needed
        
        AzDoProject 'MyProject' {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            ProjectDescription   = 'Sample project'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
    }
}
```

### Setting Up Managed Identity

1. **For Azure VM**:
   ```powershell
   # Enable system-assigned identity
   Update-AzVm -ResourceGroupName $rg -VmName $vm -IdentityType SystemAssigned
   ```

2. **Grant permissions** to the identity in Azure DevOps:
   - Add the identity as a member of appropriate groups
   - Assign necessary permissions

3. **On the resource**:
   - Managed Identity is automatically available
   - Use without explicit credential configuration

### Best Practices for Managed Identity

- ✅ Use for Azure-hosted resources
- ✅ Use system-assigned identity when possible
- ✅ Principle of least privilege - grant minimal required permissions
- ✅ No token rotation needed
- ✅ Audit identity access regularly

## Service Principal

Service Principals are ideal for CI/CD pipelines and cross-tenant scenarios.

### Creating a Service Principal

```powershell
# Create a service principal
$sp = New-AzADServicePrincipal -DisplayName "AzureDevOpsDsc-ServicePrincipal"

# Note the Application ID and Tenant ID for later use
$appId = $sp.AppId
$tenantId = (Get-AzContext).Tenant.Id
```

### Using Service Principal

```powershell
Configuration ExampleWithServicePrincipal {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        $authToken = @{
            ServicePrincipalId = 'your-app-id'
            ServicePrincipalSecret = 'your-client-secret'
            TenantId = 'your-tenant-id'
            OrganizationName = 'your-org-name'
        }
        
        AzDoProject 'MyProject' {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            ProjectDescription   = 'Sample project'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
    }
}
```

### Best Practices for Service Principal

- ✅ Use in automated/CI-CD scenarios
- ✅ Store secrets in Key Vault
- ✅ Use certificate-based auth instead of client secret when possible
- ✅ Rotate secrets regularly
- ✅ Use minimal required permissions
- ✅ Audit service principal activity
- ❌ Don't hardcode credentials
- ❌ Don't commit secrets to version control

## Certificate-Based Authentication

Certificate-based authentication provides additional security for service principals.

### Creating a Certificate

```powershell
# Create self-signed certificate
$cert = New-SelfSignedCertificate `
    -Subject "CN=AzureDevOpsDsc" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyExportPolicy Exportable `
    -KeySpec Signature

# Export certificate
$thumbprint = $cert.Thumbprint
Export-PfxCertificate -Cert $cert -FilePath "C:\cert.pfx" -Password (ConvertTo-SecureString -String "password" -AsPlainText)
```

### Using Certificate Authentication

```powershell
Configuration ExampleWithCertificate {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        $authToken = @{
            ServicePrincipalId = 'your-app-id'
            CertificateThumbprint = 'your-cert-thumbprint'
            TenantId = 'your-tenant-id'
            OrganizationName = 'your-org-name'
        }
        
        AzDoProject 'MyProject' {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            ProjectDescription   = 'Sample project'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
    }
}
```

### Best Practices for Certificates

- ✅ More secure than client secrets
- ✅ Longer expiration than secrets
- ✅ Store certificate securely
- ✅ Monitor certificate expiration
- ✅ Rotate before expiration
- ❌ Don't share certificates

## Azure CLI Token

Use your existing Azure CLI session for authentication.

### Prerequisites

- Azure CLI installed and authenticated
- Run `az login` to authenticate first

### Using Azure CLI Token

```powershell
# Azure CLI authentication is automatic if you've run 'az login'
Configuration ExampleWithAzureCli {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # No explicit credential configuration needed
        # Uses current Azure CLI context
        
        AzDoProject 'MyProject' {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            ProjectDescription   = 'Sample project'
            SourceControlType    = 'Git'
            ProcessTemplate      = 'Agile'
            Visibility           = 'Private'
        }
    }
}
```

### Best Practices for Azure CLI

- ✅ Convenient for local development
- ✅ Automatically uses your Azure login
- ✅ Token automatically refreshed
- ✅ No manual credential management
- ❌ Not ideal for automated scenarios
- ❌ Only works on machines with Azure CLI installed

## Workload Identity Federation

Keyless authentication for GitHub Actions, GitLab CI, and other CI/CD systems.

### Setting Up Workload Identity

1. **Register your OIDC provider** with Azure AD
2. **Create a service principal** and configure trust
3. **Configure your CI/CD pipeline** to use federated credentials

### Using in CI/CD Pipeline

```yaml
# GitHub Actions example
name: Deploy with Azure DevOps DSC

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Run DSC Configuration
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Apply Configuration
        run: |
          pwsh -Command {
              # DSC configuration runs here
              ./ApplyDscConfig.ps1
          }
```

### Best Practices for Workload Identity

- ✅ No secrets stored in CI/CD
- ✅ Short-lived tokens
- ✅ Secure by default
- ✅ Audit trail in OIDC provider
- ✅ Recommended for modern CI/CD systems

## Environment Variables

Set environment variables for authentication:

```powershell
# PAT
$env:AZDO_PAT = 'your-token'
$env:AZDO_ORG = 'your-organization'

# Service Principal
$env:AZDO_SERVICE_PRINCIPAL_ID = 'your-app-id'
$env:AZDO_SERVICE_PRINCIPAL_SECRET = 'your-secret'
$env:AZDO_TENANT_ID = 'your-tenant-id'

# Managed Identity
$env:AZDO_MANAGED_IDENTITY = 'true'
```

## Storing Credentials Securely

### Option 1: Windows Credential Manager

```powershell
# Store PAT in Credential Manager
$cred = New-Object System.Management.Automation.PSCredential(
    'AzureDevOpsDsc',
    (ConvertTo-SecureString 'your-pat-token' -AsPlainText -Force)
)
$cred | Export-Clixml -Path "$env:APPDATA\AzureDevOpsDsc\cred.xml"

# Retrieve in configuration
$cred = Import-Clixml -Path "$env:APPDATA\AzureDevOpsDsc\cred.xml"
```

### Option 2: Azure Key Vault

```powershell
# Store in Key Vault
Set-AzKeyVaultSecret -VaultName 'MyKeyVault' `
    -Name 'AzureDevOpsPAT' `
    -SecretValue (ConvertTo-SecureString 'your-pat-token' -AsPlainText -Force)

# Retrieve in configuration
$token = Get-AzKeyVaultSecret -VaultName 'MyKeyVault' -Name 'AzureDevOpsPAT'
```

### Option 3: PowerShell SecretStore

```powershell
# Install SecretStore module
Install-Module Microsoft.PowerShell.SecretStore

# Store credential
Set-Secret -Name AzureDevOpsPAT -Secret 'your-pat-token' -Vault SecretStore

# Retrieve in configuration
$token = Get-Secret -Name AzureDevOpsPAT
```

## Troubleshooting Authentication

### Issue: "Authentication Failed"

**Solution**: Verify your token/credentials:
```powershell
# Test connectivity
Get-DscResource -Module AzureDevOpsDscNative
```

### Issue: "Insufficient Permissions"

**Solution**: Ensure your authentication account has necessary permissions in Azure DevOps:
- Check group memberships
- Verify permission assignments
- Review scope settings (for PAT)

### Issue: "Token Expired"

**Solution**: Refresh or regenerate:
- Create new PAT
- Rotate service principal secret
- Re-authenticate with Azure CLI

### Issue: "Cannot Find Resource"

**Solution**: Verify module is installed:
```powershell
# List installed modules
Get-Module -ListAvailable | Where-Object Name -eq AzureDevOpsDscNative

# Import module explicitly
Import-Module -Name AzureDevOpsDscNative
```

## Choosing the Right Authentication Method

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| **PAT** | General use, local dev | Simple, flexible | Requires token management |
| **Managed Identity** | Azure resources | No credential mgmt, secure | Azure-only |
| **Service Principal** | CI/CD, automation | Cross-tenant, automated | Secret management needed |
| **Certificate** | Secure scenarios | More secure than secret | More complex setup |
| **Azure CLI** | Local development | Automatic, convenient | Not for automation |
| **Workload Identity** | Modern CI/CD | Keyless, secure | Setup complexity |

## Security Checklist

- [ ] Use minimal required permissions
- [ ] Store credentials securely (not in code)
- [ ] Rotate credentials regularly
- [ ] Monitor authentication logs
- [ ] Use expiration dates on tokens
- [ ] Revoke unused credentials
- [ ] Audit who has access
- [ ] Use MFA for personal accounts
- [ ] Enable activity logging
- [ ] Review access regularly
