<#
.SYNOPSIS
    DSC resource for managing Azure DevOps deployment environments.
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoPipelineEnvironment : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$EnvironmentName
    [DscProperty()][System.String]$Description

    AzDoPipelineEnvironment() { $this.Construct() }

    [AzDoPipelineEnvironment] Get() { return [AzDoPipelineEnvironment]$($this.GetDscCurrentStateProperties()) }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport() { return @() }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject) {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName     = $CurrentResourceObject.ProjectName
        $properties.EnvironmentName = $CurrentResourceObject.EnvironmentName
        $properties.Description     = $CurrentResourceObject.Description
        $properties.LookupResult    = $CurrentResourceObject.LookupResult
        $properties.Ensure          = $CurrentResourceObject.Ensure
        Write-Verbose "[AzDoPipelineEnvironment] Current state properties: $($properties | Out-String)"
        return $properties
    }
}