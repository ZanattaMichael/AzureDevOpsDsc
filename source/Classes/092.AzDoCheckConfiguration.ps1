<#
.SYNOPSIS
    DSC resource for managing pipeline check configurations.
.DESCRIPTION
    This resource manages pipeline check configurations on Azure DevOps resources such as
    environments, repositories, and service connections. Checks enforce gates that must pass before
    a pipeline can access the protected resource.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER ResourceType
    The type of resource. Valid values are environment, repository, and endpoint. This is a key property.

.PARAMETER CheckType
    The type of check to configure (e.g., Task Check, Approval, ExclusiveLock). This is a key property.

.PARAMETER Settings
    A hashtable of check-specific configuration settings.

.PARAMETER TimeoutInMinutes
    How long the check can run before timing out. Defaults to 43200 (30 days).

.PARAMETER Enabled
    Whether the check is active. Defaults to $true.

.PARAMETER TargetResourceName
    The name of the resource the check is attached to - an environment name, repository name
    or service connection name, depending on ResourceType. This property is mandatory.

#>

[DscResource()]
class AzDoCheckConfiguration : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$TargetResourceName

    [DscProperty(Mandatory)]
    [ValidateSet('environment','repository','endpoint')]
    [System.String]$ResourceType

    [DscProperty(Mandatory)]
    [System.String]$CheckType

    [DscProperty()]
    [HashTable]$Settings

    [DscProperty()]
    [System.UInt32]$TimeoutInMinutes = 43200

    [DscProperty()]
    [System.Boolean]$Enabled = $true

    AzDoCheckConfiguration()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoCheckConfiguration] Get()
    {
        return [AzDoCheckConfiguration]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName          = $CurrentResourceObject.ProjectName
        $properties.TargetResourceName   = $CurrentResourceObject.TargetResourceName
        $properties.ResourceType         = $CurrentResourceObject.ResourceType
        $properties.CheckType        = $CurrentResourceObject.CheckType
        $properties.Settings         = $CurrentResourceObject.Settings
        $properties.TimeoutInMinutes = $CurrentResourceObject.TimeoutInMinutes
        $properties.Enabled          = $CurrentResourceObject.Enabled
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure
        return $properties
    }
}
