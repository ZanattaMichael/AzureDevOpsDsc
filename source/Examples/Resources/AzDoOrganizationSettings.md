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
    [ EnableIPConditionalAccessPolicyValidation = [String] {'', 'true', 'false'} ]
    [ LogAuditEvents               = [String] {'', 'true', 'false'} ]
    [ AllowTeamAdminsToInviteUsers = [String] {'', 'true', 'false'} ]
    [ EnableRequestAccess          = [String] {'', 'true', 'false'} ]
    [ RequestAccessUrl             = [String]$RequestAccessUrl ]
    [ EnableArtifactsFeedUpstreamProtection = [String] {'', 'true', 'false'} ]
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
- **LogAuditEvents**: Whether organization audit events are logged (*Organization settings -> Policies -> Security -> "Log audit events"*). Setting this to `'false'` warns that any `AzDoAuditStream` on the organization will receive no events while auditing is off.
- **AllowTeamAdminsToInviteUsers**: Whether team and project administrators can invite new users (*Organization settings -> Policies -> User -> "Allow team and project administrators to invite new users"*).
- **EnableRequestAccess**: Whether the "Request access" link is shown to users without access (*Organization settings -> Policies -> User -> "Request access"*).
- **RequestAccessUrl**: The URL shown alongside the request-access prompt. Only compared and written when `EnableRequestAccess` is `'true'` and this is not empty. The service's field for this URL has not yet been confirmed against a live organization.
- **EnableArtifactsFeedUpstreamProtection**: Whether additional protections are applied when Artifacts feeds use public package registries as an upstream source (*Organization settings -> Policies -> Security -> "Additional protections when using public package registries"*).
- **Ensure**: Specifies whether the settings should be applied. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages organization-level security and access settings in Azure DevOps. These settings affect the entire organization and should be managed carefully. Only one instance of this resource should be configured per organization.

`AllowPublicProjects`, `AllowExternalGuestAccess`, `EnableOAuthAuthentication`, `EnableSSHAuthentication` and
`DisallowAadGuestUserPolicy` are read/written via `_apis/settings/entries/host`.

The organization policy properties (`EnableIPConditionalAccessPolicyValidation`, `LogAuditEvents`,
`AllowTeamAdminsToInviteUsers`, `EnableRequestAccess`/`RequestAccessUrl` and
`EnableArtifactsFeedUpstreamProtection`) are a separate mechanism, matching the *Organization settings ->
Policies* page:

- **Write**: `PATCH _apis/OrganizationPolicy/Policies/{policyName}?api-version=5.0-preview.1` with a JSON
  patch array, e.g. `[{"from":"","op":2,"path":"/Value","value":"true"}]`.
- **Read**: that route has no GET (it answers `405 Method Not Allowed`). The policies are read from the
  page's data provider, `ms.vss-org-web.collection-admin-policy-data-provider`, through
  `_apis/Contribution/HierarchyQuery`, falling back to the page's own data route
  (`_settings/organizationPolicy?__rt=fps&__ver=2`). All policies come back in one call. Both are the web
  page's routes and can return no policy data to a service principal or managed identity; when they do,
  each policy is read on its own from the organization's SPS host
  (`GET https://vssps.dev.azure.com/{org}/_apis/OrganizationPolicy/Policies/{policyName}`). If every
  route fails, the error says what each one returned. The value compared is the policy's
  `effectiveValue` (what is in force), falling back to `value`.
- **Read failures**: a failed policy read is an error only when the configuration sets a policy property
  (or `RequestAccessUrl`). A configuration that manages only the host settings above gets a warning
  instead, and its host settings are still compared, so it never depends on the policy read.

### Tri-state policy properties

The policy properties take `'true'`, `'false'` or `''` (the default). `''` means *unmanaged*: the policy is
neither compared nor written. `$true` and `$false` in a configuration are accepted and converted.

They are strings rather than booleans because the resource base class passes every property to Get and Set.
An unset `[Boolean]` arrives as `$false`, so a configuration that set only `LogAuditEvents` would also have
switched the other four policies off. `Get` reports each policy as `'true'` or `'false'`.

> The five host-settings properties above are still `[Boolean]` and have that problem: when any of them is
> left unset, `Set` writes it as `$false`. Until they are converted too, state all five explicitly whenever
> this resource is applied.

A `LimitUserVisibility` property was considered but left out: it verified as a preview-feature flag rather
than a confirmed organization policy. Microsoft Entra tenant-level policies (PAT restrictions,
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
            LogAuditEvents             = 'true'
            AllowTeamAdminsToInviteUsers = 'false'
            EnableRequestAccess        = 'true'
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
    LogAuditEvents: 'true'
    AllowTeamAdminsToInviteUsers: 'false'
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
