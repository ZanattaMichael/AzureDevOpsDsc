<#
.SYNOPSIS
    DSC resource for managing Azure DevOps Marketplace extensions.
.DESCRIPTION
    This resource manages the installation of extensions from the Visual Studio Marketplace in an
    Azure DevOps organization. To find the PublisherId and ExtensionId for an extension, look at
    its URL in the Marketplace:
    https://marketplace.visualstudio.com/items?itemName={PublisherId}.{ExtensionId}

.PARAMETER PublisherId
    The publisher ID of the extension in the Visual Studio Marketplace. This property is mandatory and serves as a key property for the resource.

.PARAMETER ExtensionId
    The extension ID in the Visual Studio Marketplace. This is a key property.

.PARAMETER Version
    The installed version of the extension. Read-only - it is reported by Get and cannot be set.

.PARAMETER DisplayName
    The display name of the extension as published in the Marketplace. Read-only - it is
    reported by Get and cannot be set.

#>

[DscResource()]
class AzDoExtension : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$PublisherId

    [DscProperty(Mandatory)]
    [System.String]$ExtensionId

    [DscProperty(NotConfigurable)]
    [System.String]$Version

    [DscProperty(NotConfigurable)]
    [System.String]$DisplayName

    AzDoExtension()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoExtension] Get()
    {
        return [AzDoExtension]$($this.GetDscCurrentStateProperties())
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

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.PublisherId  = $CurrentResourceObject.PublisherId
        $properties.ExtensionId  = $CurrentResourceObject.ExtensionId
        $properties.Version      = $CurrentResourceObject.Version
        $properties.DisplayName  = $CurrentResourceObject.DisplayName
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoExtension] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
