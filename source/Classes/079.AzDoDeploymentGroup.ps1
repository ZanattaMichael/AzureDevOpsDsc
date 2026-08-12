<#
.SYNOPSIS
    DSC resource for managing Azure DevOps deployment groups.
#>

[DscResource()]
class AzDoDeploymentGroup : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$DeploymentGroupName

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.String[]]$Tags

    AzDoDeploymentGroup()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoDeploymentGroup] Get()
    {
        return [AzDoDeploymentGroup]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName          = $CurrentResourceObject.ProjectName
        $properties.DeploymentGroupName  = $CurrentResourceObject.DeploymentGroupName
        $properties.Description          = $CurrentResourceObject.Description
        $properties.Tags                 = $CurrentResourceObject.Tags
        $properties.LookupResult         = $CurrentResourceObject.LookupResult
        $properties.Ensure               = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoDeploymentGroup] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
