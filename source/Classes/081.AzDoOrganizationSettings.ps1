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
        }
        else
        {
            $properties.AllowPublicProjects        = $CurrentResourceObject.AllowPublicProjects
            $properties.AllowExternalGuestAccess   = $CurrentResourceObject.AllowExternalGuestAccess
            $properties.EnableOAuthAuthentication  = $CurrentResourceObject.EnableOAuthAuthentication
            $properties.EnableSSHAuthentication    = $CurrentResourceObject.EnableSSHAuthentication
            $properties.DisallowAadGuestUserPolicy = $CurrentResourceObject.DisallowAadGuestUserPolicy
        }

        Write-Verbose "[AzDoOrganizationSettings] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
