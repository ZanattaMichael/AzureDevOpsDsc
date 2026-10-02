<#
.SYNOPSIS
    DSC resource for managing Azure DevOps group licensing rules.

.DESCRIPTION
    Manages the group entitlement (licensing rule) that assigns an access level to every member of
    a group. This is how licensing is administered at scale; AzDoUserEntitlement covers a single
    user at a time, which does not scale to an organization.

.NOTES
    Author: Michael Zanatta

    The rule applies to the group's members, so changing AccountLicenseType re-licenses everyone
    the group covers. Reducing a rule from 'express' to 'stakeholder' takes Basic access away from
    every member who has no other rule or direct assignment granting it.

    Removing the rule (Ensure = 'Absent') does not remove anyone from the organization. Members
    keep any license held directly or granted by another rule; they lose only what this rule gave
    them.

.PARAMETER GroupDisplayName
    The display name or principal name of the group the rule applies to.

.PARAMETER AccountLicenseType
    The access level the rule assigns, for example 'express' (Basic), 'stakeholder' or 'advanced'.

.PARAMETER GroupOrigin
    The identity origin: 'aad' for a Microsoft Entra group, 'vsts' for an Azure DevOps group.
    Defaults to 'aad'.

.PARAMETER GroupOriginId
    The Entra object id of the group. Supplying it makes creation unambiguous when several groups
    share a display name.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoGroupEntitlement Developers
    {
        GroupDisplayName   = 'Contoso Developers'
        AccountLicenseType = 'express'
        Ensure             = 'Present'
    }
#>

[DscResource()]
class AzDoGroupEntitlement : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [Alias('GroupName')]
    [System.String]$GroupDisplayName

    [DscProperty()]
    [System.String]$AccountLicenseType

    [DscProperty()]
    [ValidateSet('aad', 'vsts')]
    [System.String]$GroupOrigin = 'aad'

    [DscProperty()]
    [System.String]$GroupOriginId

    AzDoGroupEntitlement()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoGroupEntitlement] Get()
    {
        return [AzDoGroupEntitlement]$($this.GetDscCurrentStateProperties())
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

        $properties.GroupDisplayName   = $CurrentResourceObject.GroupDisplayName
        $properties.AccountLicenseType = $CurrentResourceObject.AccountLicenseType
        $properties.GroupOrigin        = $CurrentResourceObject.GroupOrigin
        $properties.GroupOriginId      = $CurrentResourceObject.GroupOriginId
        $properties.LookupResult       = $CurrentResourceObject.LookupResult
        $properties.Ensure             = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoGroupEntitlement] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
