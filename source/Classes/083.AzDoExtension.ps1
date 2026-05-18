<#
.SYNOPSIS
    DSC resource for managing Azure DevOps Marketplace extensions.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoExtension : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$PublisherId

    [DscProperty(Key, Mandatory)]
    [System.String]$ExtensionId

    [DscProperty(NotConfigurable)]
    [System.String]$Version

    [DscProperty(NotConfigurable)]
    [System.String]$DisplayName

    AzDoExtension()
    {
        $this.Construct()
    }

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