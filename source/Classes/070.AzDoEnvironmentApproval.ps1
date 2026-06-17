<#
.SYNOPSIS
    DSC resource for managing Azure DevOps environment approval checks.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
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