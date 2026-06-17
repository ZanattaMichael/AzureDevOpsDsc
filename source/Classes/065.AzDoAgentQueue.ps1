<#
.SYNOPSIS
    DSC resource for managing Azure DevOps agent queues.
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoAgentQueue : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$QueueName
    [DscProperty(Mandatory)][System.String]$PoolName
    [DscProperty()][System.Boolean]$AuthorizeAllPipelines = $false

    AzDoAgentQueue() { $this.Construct() }
    [AzDoAgentQueue] Get() { return [AzDoAgentQueue]$($this.GetDscCurrentStateProperties()) }
    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport() { return @() }
    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject) {
        $properties = @{ Ensure=[Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName          = $CurrentResourceObject.ProjectName
        $properties.QueueName            = $CurrentResourceObject.QueueName
        $properties.PoolName             = $CurrentResourceObject.PoolName
        $properties.AuthorizeAllPipelines = $CurrentResourceObject.AuthorizeAllPipelines
        $properties.LookupResult         = $CurrentResourceObject.LookupResult
        $properties.Ensure               = $CurrentResourceObject.Ensure
        return $properties
    }
}