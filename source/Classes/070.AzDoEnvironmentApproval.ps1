<#
.SYNOPSIS
    DSC resource for managing Azure DevOps environment approval checks.
.DESCRIPTION
    This resource configures approval gates on Azure DevOps pipeline environments. When an approval
    check is configured, deployments to that environment will pause until the required number of
    approvers have approved the deployment.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER EnvironmentName
    The name of the pipeline environment. This is a key property.

.PARAMETER RequiredApproverCount
    The minimum number of approvals required. Defaults to 1.

.PARAMETER AllowApproverToSelf
    Whether the user who triggered the pipeline can approve their own deployment. Defaults to $false.

.PARAMETER TimeoutInMinutes
    How long the approval check waits before timing out. Defaults to 43200 (30 days).

.PARAMETER Instructions
    Instructions shown to approvers. Optional.

#>

[DscResource()]
class AzDoEnvironmentApproval : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$EnvironmentName

    [DscProperty(Mandatory)]
    [System.String[]]$Approvers

    [DscProperty()]
    [System.UInt32]$RequiredApproverCount = 1

    [DscProperty()]
    [System.Boolean]$AllowApproverToSelf = $false

    [DscProperty()]
    [System.UInt32]$TimeoutInMinutes = 43200

    [DscProperty()]
    [System.String]$Instructions

    AzDoEnvironmentApproval()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoEnvironmentApproval] Get()
    {
        return [AzDoEnvironmentApproval]$($this.GetDscCurrentStateProperties())
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

        $properties.ProjectName           = $CurrentResourceObject.ProjectName
        $properties.EnvironmentName       = $CurrentResourceObject.EnvironmentName
        $properties.Approvers             = $CurrentResourceObject.Approvers
        $properties.RequiredApproverCount = $CurrentResourceObject.RequiredApproverCount
        $properties.AllowApproverToSelf   = $CurrentResourceObject.AllowApproverToSelf
        $properties.TimeoutInMinutes      = $CurrentResourceObject.TimeoutInMinutes
        $properties.Instructions          = $CurrentResourceObject.Instructions
        $properties.LookupResult          = $CurrentResourceObject.LookupResult
        $properties.Ensure                = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoEnvironmentApproval] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
