<#
.SYNOPSIS
    DSC resource for managing Azure DevOps agent queues.
.DESCRIPTION
    This resource manages agent queues within Azure DevOps projects. An agent queue is the project-
    level reference to an organization-level agent pool, allowing pipelines in the project to use
    that pool.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER QueueName
    The name of the agent queue within the project. This is a key property.

.PARAMETER PoolName
    The name of the agent pool that backs this queue. This is a mandatory property.

.PARAMETER AuthorizeAllPipelines
    Whether every pipeline in the project is granted access to the queue without an explicit
    authorization prompt. Defaults to $false.

#>
[DscResource()]
class AzDoAgentQueue : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$QueueName
    [DscProperty(Mandatory)][System.String]$PoolName
    [DscProperty()][System.Boolean]$AuthorizeAllPipelines = $false

    AzDoAgentQueue() { $this.Construct() }
    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
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
