<#
.SYNOPSIS
    DSC resource for managing Azure DevOps deployment groups.
.DESCRIPTION
    This resource manages Azure DevOps deployment groups, which are collections of physical or
    virtual machines used as deployment targets for classic release pipelines. Agents installed on
    these machines register with the deployment group to receive deployments.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER DeploymentGroupName
    The name of the deployment group. This is a key property.

.PARAMETER Description
    An optional description for the deployment group.

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
