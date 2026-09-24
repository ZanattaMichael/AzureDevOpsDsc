# DSC AzDoOrganizationSettings Resource

## Syntax

```PowerShell
AzDoOrganizationSettings [string] #ResourceName
{
    OrganizationName               = [String]$OrganizationName
    [ AllowPublicProjects          = [Boolean]$AllowPublicProjects ]
    [ AllowExternalGuestAccess     = [Boolean]$AllowExternalGuestAccess ]
    [ EnableOAuthAuthentication    = [Boolean]$EnableOAuthAuthentication ]
    [ EnableSSHAuthentication      = [Boolean]$EnableSSHAuthentication ]
    [ DisallowAadGuestUserPolicy   = [Boolean]$DisallowAadGuestUserPolicy ]
    [ EnableIPConditionalAccessPolicyValidation = [Boolean]$EnableIPConditionalAccessPolicyValidation ]
    [ LogAuditEvents               = [Boolean]$LogAuditEvents ]
    [ AllowTeamAdminsToInviteUsers = [Boolean]$AllowTeamAdminsToInviteUsers ]
    [ EnableRequestAccess          = [Boolean]$EnableRequestAccess ]
    [ RequestAccessUrl             = [String]$RequestAccessUrl ]
    [ EnableArtifactsFeedUpstreamProtection = [Boolean]$EnableArtifactsFeedUpstreamProtection ]
    [ Ensure                       = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **OrganizationName**: The name of the Azure DevOps organization. This property is mandatory and serves as the key property for the resource. It is not configurable after initial setup.
- **AllowPublicProjects**: Whether users can create public (anonymous-access) projects.
- **AllowExternalGuestAccess**: Whether external guest users (Azure AD guests) can be added to the organization.
- **EnableOAuthAuthentication**: Whether OAuth authentication is enabled for third-party applications.
- **EnableSSHAuthentication**: Whether SSH authentication is enabled for Git operations.
- **DisallowAadGuestUserPolicy**: Whether the Azure AD guest user policy is disallowed.
- **EnableIPConditionalAccessPolicyValidation**: Whether IP Conditional Access policy validation is enforced for this organization (*Organization settings -> Policies -> Security -> "Enable IP Conditional Access policy validation"*).
- **LogAuditEvents**: Whether organization audit events are logged (*Organization settings -> Policies -> Security -> "Log audit events"*). Setting this to `$false` warns that any `AzDoAuditStream` on the organization will receive no events while auditing is off.
- **AllowTeamAdminsToInviteUsers**: Whether team and project administrators can invite new users (*Organization settings -> Policies -> User -> "Allow team and project administrators to invite new users"*).
- **EnableRequestAccess**: Whether the "Request access" link is shown to users without access (*Organization settings -> Policies -> User -> "Request access"*).
- **RequestAccessUrl**: The URL shown alongside the request-access prompt. Only compared and written when `EnableRequestAccess` is `$true`.
- **EnableArtifactsFeedUpstreamProtection**: Whether additional protections are applied when Artifacts feeds use public package registries as an upstream source (*Organization settings -> Policies -> Security -> "Additional protections when using public package registries"*).
- **Ensure**: Specifies whether the settings should be applied. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages organization-level security and access settings in Azure DevOps. These settings affect the entire organization and should be managed carefully. Only one instance of this resource should be configured per organization.

`AllowPublicProjects`, `AllowExternalGuestAccess`, `EnableOAuthAuthentication`, `EnableSSHAuthentication` and
`DisallowAadGuestUserPolicy` are read/written via `_apis/settings/entries/host`. The policy properties added
after them (`EnableIPConditionalAccessPolicyValidation`, `LogAuditEvents`, `AllowTeamAdminsToInviteUsers`,
`EnableRequestAccess`/`RequestAccessUrl` and `EnableArtifactsFeedUpstreamProtection`) are a separate
mechanism, `_apis/OrganizationPolicy/Policies/{policyName}`, matching the *Organization settings -> Policies*
page. A `LimitUserVisibility` property was considered but left out: it verified as a preview-feature flag
rather than a confirmed organization policy. Microsoft Entra tenant-level policies (PAT restrictions,
organization-creation restrictions) are a different scope, tracked separately.

## Examples

## Example 1: Sample Configuration using AzDoOrganizationSettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoOrganizationSettings ConfigureOrgSettings {
            Ensure                     = 'Present'
            OrganizationName           = 'SampleAzDoOrgName'
            AllowPublicProjects        = $false
            AllowExternalGuestAccess   = $false
            EnableOAuthAuthentication  = $true
            EnableSSHAuthentication    = $true
            DisallowAadGuestUserPolicy = $false
            LogAuditEvents             = $true
            AllowTeamAdminsToInviteUsers = $false
            EnableRequestAccess        = $true
            RequestAccessUrl           = 'https://contoso.example/request-access'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoOrganizationSettings
$properties = @{
    OrganizationName = 'SampleAzDoOrgName'
}

Invoke-DscResource -Name 'AzDoOrganizationSettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  OrganizationName: SampleAzDoOrgName
}

resources:
- name: Organization Security Settings
  type: AzureDevOpsDscNative/AzDoOrganizationSettings
  properties:
    OrganizationName: $OrganizationName
    AllowPublicProjects: false
    AllowExternalGuestAccess: false
    EnableOAuthAuthentication: true
    EnableSSHAuthentication: true
    DisallowAadGuestUserPolicy: false
    Ensure: Present
```

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
