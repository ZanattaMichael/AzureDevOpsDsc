<#
.SYNOPSIS
    DSC resource for managing Azure DevOps deployment environments.
.DESCRIPTION
    This resource manages pipeline environments in Azure DevOps. Environments represent deployment
    targets (e.g., Development, Staging, Production) and can be configured with approval gates and
    checks using the AzDoEnvironmentApproval and AzDoCheckConfiguration resources.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER EnvironmentName
    The name of the pipeline environment. This is a key property.

.PARAMETER Description
    An optional description for the environment.

#>
[DscResource()]
class AzDoPipelineEnvironment : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$EnvironmentName
    [DscProperty()][System.String]$Description

    AzDoPipelineEnvironment() { $this.Construct() }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
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
