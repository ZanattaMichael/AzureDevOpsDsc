<#
.SYNOPSIS
    DSC resource for managing Azure DevOps user entitlements (organization membership + access level).

.DESCRIPTION
    The AzDoUserEntitlement resource adds and removes users from an Azure DevOps organization and manages
    their access level (account license type) via the Member Entitlement Management API. It inherits
    Test()/Set() from the AzDevOpsDscResourceBase class.

.PARAMETER UserPrincipalName
    The user's principal name (email / UPN).

.PARAMETER AccountLicenseType
    The account license type to assign. Valid values are 'stakeholder', 'express' (Basic),
    'advanced' (Basic + Test Plans), 'professional', 'earlyAdopter' and 'none'.

.EXAMPLE
    AzDoUserEntitlement JaneBasic
    {
        UserPrincipalName  = 'jane@contoso.com'
        AccountLicenseType = 'express'
        Ensure             = 'Present'
    }
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoUserEntitlement : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('PrincipalName')]
    [System.String]$UserPrincipalName

    [DscProperty(Mandatory)]
    [ValidateSet('stakeholder', 'express', 'advanced', 'professional', 'earlyAdopter', 'none')]
    [System.String]$AccountLicenseType

    AzDoUserEntitlement()
    {
        $this.Construct()
    }

    [AzDoUserEntitlement] Get()
    {
        return [AzDoUserEntitlement]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.UserPrincipalName  = $CurrentResourceObject.UserPrincipalName
        $properties.AccountLicenseType = $CurrentResourceObject.AccountLicenseType
        $properties.LookupResult        = $CurrentResourceObject.LookupResult
        $properties.Ensure              = $CurrentResourceObject.Ensure
        return $properties
    }
}
