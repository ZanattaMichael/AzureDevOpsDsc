<#
.SYNOPSIS
    DSC resource for managing Azure DevOps service principal entitlements.

.DESCRIPTION
    Manages a service principal or managed identity as a member of the organization, with an
    access level. Service principals are organization members in their own right and are not
    covered by AzDoUserEntitlement, which handles users only.

    The module can already authenticate as a service principal, a certificate-backed service
    principal, or a federated workload identity - this closes the matching gap on the managed side.

.NOTES
    Author: Michael Zanatta

    Identity is matched by OriginId, the Microsoft Entra object id, rather than by display name.
    Display names are neither unique nor stable, and a rename in Entra does not change the
    entitlement, so matching by name would make the resource create duplicates after a rename.

    The service principal entitlements endpoint is a preview API. If an organization does not
    expose it, the lookup reports the entitlement as absent rather than failing the configuration.

    Ensure = 'Absent' removes the service principal from the organization, so anything running as
    that identity - pipelines, federated deployments - loses access.

.PARAMETER OriginId
    The Microsoft Entra object id of the service principal.

.PARAMETER DisplayName
    A display name recorded with the entitlement. Informational; matching uses OriginId.

.PARAMETER AccountLicenseType
    The access level to assign, for example 'express' (Basic) or 'stakeholder'.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoServicePrincipalEntitlement DeploymentIdentity
    {
        OriginId           = '00000000-0000-0000-0000-000000000000'
        DisplayName        = 'contoso-deployment-sp'
        AccountLicenseType = 'express'
        Ensure             = 'Present'
    }
#>

[DscResource()]
class AzDoServicePrincipalEntitlement : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('ObjectId')]
    [System.String]$OriginId

    [DscProperty()]
    [Alias('Name')]
    [System.String]$DisplayName

    [DscProperty()]
    [System.String]$AccountLicenseType

    AzDoServicePrincipalEntitlement()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoServicePrincipalEntitlement] Get()
    {
        return [AzDoServicePrincipalEntitlement]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.OriginId           = $CurrentResourceObject.OriginId
        $properties.DisplayName        = $CurrentResourceObject.DisplayName
        $properties.AccountLicenseType = $CurrentResourceObject.AccountLicenseType
        $properties.LookupResult       = $CurrentResourceObject.LookupResult
        $properties.Ensure             = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoServicePrincipalEntitlement] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
