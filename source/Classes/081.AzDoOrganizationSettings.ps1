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
        $properties.AllowPublicProjects           = $CurrentResourceObject.AllowPublicProjects
        $properties.AllowExternalGuestAccess      = $CurrentResourceObject.AllowExternalGuestAccess
        $properties.EnableOAuthAuthentication     = $CurrentResourceObject.EnableOAuthAuthentication
        $properties.EnableSSHAuthentication       = $CurrentResourceObject.EnableSSHAuthentication
        $properties.DisallowAadGuestUserPolicy    = $CurrentResourceObject.DisallowAadGuestUserPolicy
        $properties.LookupResult                  = $CurrentResourceObject.LookupResult
        $properties.Ensure                        = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoOrganizationSettings] Current state properties: $($properties | Out-String)"

        return $properties
    }
}