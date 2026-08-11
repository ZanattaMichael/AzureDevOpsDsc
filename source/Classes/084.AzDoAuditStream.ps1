<#
.SYNOPSIS
    DSC resource for managing Azure DevOps audit log streaming.
#>

[DscResource()]
class AzDoAuditStream : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$StreamName

    [DscProperty(Mandatory)]
    [ValidateSet('AzureMonitorLogs','Splunk','AzureEventGrid','AzureEventHub')]
    [System.String]$ConsumerType

    [DscProperty(Mandatory)]
    [HashTable]$ConsumerInputs

    [DscProperty()]
    [System.Boolean]$Enabled = $true

    AzDoAuditStream()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoAuditStream] Get()
    {
        return [AzDoAuditStream]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.StreamName     = $CurrentResourceObject.StreamName
        $properties.ConsumerType   = $CurrentResourceObject.ConsumerType
        $properties.ConsumerInputs = $CurrentResourceObject.ConsumerInputs
        $properties.Enabled        = $CurrentResourceObject.Enabled
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure
        return $properties
    }
}
