<#
.SYNOPSIS
    DSC resource for managing Azure DevOps organisation-level settings (singleton).
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
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