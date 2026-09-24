<#
.SYNOPSIS
    DSC resource for managing Azure DevOps organisation-level settings (singleton).
.DESCRIPTION
    This resource manages organization-level security and access settings in Azure DevOps. These
    settings affect the entire organization and should be managed carefully. Only one instance of
    this resource should be configured per organization.

.PARAMETER OrganizationName
    The name of the Azure DevOps organization. This property is mandatory and serves as the key property for the resource. It is not configurable after initial setup.

.PARAMETER AllowPublicProjects
    Whether users can create public (anonymous-access) projects.

.PARAMETER AllowExternalGuestAccess
    Whether external guest users (Azure AD guests) can be added to the organization.

.PARAMETER EnableOAuthAuthentication
    Whether OAuth authentication is enabled for third-party applications.

.PARAMETER EnableSSHAuthentication
    Whether SSH authentication is enabled for Git operations.

.PARAMETER DisallowAadGuestUserPolicy
    Whether the Azure AD guest user policy is disallowed.

.PARAMETER EnableIPConditionalAccessPolicyValidation
    Whether IP Conditional Access policy validation is enforced for this organization (Organization
    settings -> Policies -> Security -> "Enable IP Conditional Access policy validation"). Backed by the
    organization policy API, not the host settings entries used by the properties above.

.PARAMETER LogAuditEvents
    Whether organization audit events are logged (Organization settings -> Policies -> Security ->
    "Log audit events"). Turning this off means an `AzDoAuditStream` on this organization receives
    nothing; `Set-AzDoOrganizationSettings` warns when this is set to `$false`.

.PARAMETER AllowTeamAdminsToInviteUsers
    Whether team and project administrators can invite new users (Organization settings -> Policies ->
    User -> "Allow team and project administrators to invite new users").

.PARAMETER EnableRequestAccess
    Whether the "Request access" link is shown to users without access (Organization settings ->
    Policies -> User -> "Request access").

.PARAMETER RequestAccessUrl
    The URL shown alongside the request-access prompt. Only meaningful, compared and written when
    `EnableRequestAccess` is `$true`.

.PARAMETER EnableArtifactsFeedUpstreamProtection
    Whether additional protections are applied when Artifacts feeds use public package registries as
    an upstream source (Organization settings -> Policies -> Security -> "Additional protections when
    using public package registries").

#>

[DscResource()]
class AzDoOrganizationSettings : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$OrganizationName

    [DscProperty()]
    [System.Boolean]$AllowPublicProjects

    [DscProperty()]
    [System.Boolean]$AllowExternalGuestAccess

    [DscProperty()]
    [System.Boolean]$EnableOAuthAuthentication

    [DscProperty()]
    [System.Boolean]$EnableSSHAuthentication

    [DscProperty()]
    [System.Boolean]$DisallowAadGuestUserPolicy

    [DscProperty()]
    [System.Boolean]$EnableIPConditionalAccessPolicyValidation

    [DscProperty()]
    [System.Boolean]$LogAuditEvents

    [DscProperty()]
    [System.Boolean]$AllowTeamAdminsToInviteUsers

    [DscProperty()]
    [System.Boolean]$EnableRequestAccess

    [DscProperty()]
    [System.String]$RequestAccessUrl

    [DscProperty()]
    [System.Boolean]$EnableArtifactsFeedUpstreamProtection

    AzDoOrganizationSettings()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoOrganizationSettings] Get()
    {
        return [AzDoOrganizationSettings]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @('OrganizationName')
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.OrganizationName             = $CurrentResourceObject.OrganizationName
        $properties.LookupResult                 = $CurrentResourceObject.LookupResult
        $properties.Ensure                       = $CurrentResourceObject.Ensure

        # Use live API values from the LookupResult when available so idempotency tests
        # compare actual org state rather than the DSC input values.
        $lr = $CurrentResourceObject.LookupResult
        if ($null -ne $lr -and $lr -is [Hashtable])
        {
            $properties.AllowPublicProjects        = if ($null -ne $lr.AllowPublicProjects)        { $lr.AllowPublicProjects }        else { $CurrentResourceObject.AllowPublicProjects }
            $properties.AllowExternalGuestAccess   = if ($null -ne $lr.AllowExternalGuestAccess)   { $lr.AllowExternalGuestAccess }   else { $CurrentResourceObject.AllowExternalGuestAccess }
            $properties.EnableOAuthAuthentication  = if ($null -ne $lr.EnableOAuthAuthentication)  { $lr.EnableOAuthAuthentication }  else { $CurrentResourceObject.EnableOAuthAuthentication }
            $properties.EnableSSHAuthentication    = if ($null -ne $lr.EnableSSHAuthentication)    { $lr.EnableSSHAuthentication }    else { $CurrentResourceObject.EnableSSHAuthentication }
            $properties.DisallowAadGuestUserPolicy = if ($null -ne $lr.DisallowAadGuestUserPolicy) { $lr.DisallowAadGuestUserPolicy } else { $CurrentResourceObject.DisallowAadGuestUserPolicy }

            $properties.EnableIPConditionalAccessPolicyValidation = if ($null -ne $lr.EnableIPConditionalAccessPolicyValidation) { $lr.EnableIPConditionalAccessPolicyValidation } else { $CurrentResourceObject.EnableIPConditionalAccessPolicyValidation }
            $properties.LogAuditEvents                            = if ($null -ne $lr.LogAuditEvents)                            { $lr.LogAuditEvents }                            else { $CurrentResourceObject.LogAuditEvents }
            $properties.AllowTeamAdminsToInviteUsers              = if ($null -ne $lr.AllowTeamAdminsToInviteUsers)              { $lr.AllowTeamAdminsToInviteUsers }              else { $CurrentResourceObject.AllowTeamAdminsToInviteUsers }
            $properties.EnableRequestAccess                       = if ($null -ne $lr.EnableRequestAccess)                       { $lr.EnableRequestAccess }                       else { $CurrentResourceObject.EnableRequestAccess }
            $properties.RequestAccessUrl                          = if ($null -ne $lr.RequestAccessUrl)                          { $lr.RequestAccessUrl }                          else { $CurrentResourceObject.RequestAccessUrl }
            $properties.EnableArtifactsFeedUpstreamProtection     = if ($null -ne $lr.EnableArtifactsFeedUpstreamProtection)     { $lr.EnableArtifactsFeedUpstreamProtection }     else { $CurrentResourceObject.EnableArtifactsFeedUpstreamProtection }
        }
        else
        {
            $properties.AllowPublicProjects        = $CurrentResourceObject.AllowPublicProjects
            $properties.AllowExternalGuestAccess   = $CurrentResourceObject.AllowExternalGuestAccess
            $properties.EnableOAuthAuthentication  = $CurrentResourceObject.EnableOAuthAuthentication
            $properties.EnableSSHAuthentication    = $CurrentResourceObject.EnableSSHAuthentication
            $properties.DisallowAadGuestUserPolicy = $CurrentResourceObject.DisallowAadGuestUserPolicy

            $properties.EnableIPConditionalAccessPolicyValidation = $CurrentResourceObject.EnableIPConditionalAccessPolicyValidation
            $properties.LogAuditEvents                            = $CurrentResourceObject.LogAuditEvents
            $properties.AllowTeamAdminsToInviteUsers              = $CurrentResourceObject.AllowTeamAdminsToInviteUsers
            $properties.EnableRequestAccess                       = $CurrentResourceObject.EnableRequestAccess
            $properties.RequestAccessUrl                          = $CurrentResourceObject.RequestAccessUrl
            $properties.EnableArtifactsFeedUpstreamProtection     = $CurrentResourceObject.EnableArtifactsFeedUpstreamProtection
        }

        Write-Verbose "[AzDoOrganizationSettings] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
