<#
.SYNOPSIS
    DSC resource for managing Azure DevOps agent pools.
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoAgentPool : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$PoolName
    [DscProperty()][ValidateSet('automation','deployment')][System.String]$PoolType = 'automation'
    [DscProperty()][System.Boolean]$AutoProvision = $false
    [DscProperty()][System.Boolean]$AutoUpdate = $true
    [DscProperty()][System.Boolean]$IsHosted = $false

    AzDoAgentPool() { $this.Construct() }
    [AzDoAgentPool] Get() { return [AzDoAgentPool]$($this.GetDscCurrentStateProperties()) }
    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport() { return @() }
    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject) {
        $properties = @{ Ensure=[Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.PoolName      = $CurrentResourceObject.PoolName
        $properties.PoolType      = $CurrentResourceObject.PoolType
        $properties.AutoProvision = $CurrentResourceObject.AutoProvision
        $properties.AutoUpdate    = $CurrentResourceObject.AutoUpdate
        $properties.IsHosted      = $CurrentResourceObject.IsHosted
        $properties.LookupResult  = $CurrentResourceObject.LookupResult
        $properties.Ensure        = $CurrentResourceObject.Ensure
        Write-Verbose "[AzDoAgentPool] Current state: $($properties | Out-String)"
        return $properties
    }
}