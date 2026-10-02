<#
.SYNOPSIS
    DSC resource for managing Azure DevOps service connections.
.DESCRIPTION
    This resource manages service connections in Azure DevOps, enabling pipelines to connect to
    external services such as Azure subscriptions, GitHub repositories, or Kubernetes clusters.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER ConnectionName
    The name of the service connection. This is a key property.

.PARAMETER ConnectionType
    The type of service connection (e.g., AzureRM, GitHub, Kubernetes). This is a mandatory property.

.PARAMETER Description
    An optional description for the service connection.

.PARAMETER AllowAllPipelines
    Whether all pipelines can use this service connection. Defaults to $false.

.PARAMETER Authorization
    A hashtable of authorization parameters specific to the connection type.

.PARAMETER Data
    A hashtable of additional data parameters specific to the connection type.

.PARAMETER SharedWithProjects
    Additional projects, beyond ProjectName, that the service connection is also shared with.
    Compared only when the configuration states it, so a connection shared by hand outside this
    resource is left alone. Add and remove drift against the live
    'serviceEndpointProjectReferences' is detected and corrected by Set.

.PARAMETER SharedNameOverrides
    Optional hashtable of ProjectName -> the name the service connection is shown under in that
    project, e.g. @{ Fabrikam = 'shared-azure-sub' }. Only consulted for projects named in
    SharedWithProjects; the owning project's reference always uses ConnectionName.

#>

[DscResource()]
class AzDoServiceConnection : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$ConnectionName

    [DscProperty(Mandatory)]
    [System.String]$ConnectionType

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.Boolean]$AllowAllPipelines = $false

    [DscProperty()]
    [HashTable]$Authorization

    [DscProperty()]
    [HashTable]$Data

    [DscProperty()]
    [System.String[]]$SharedWithProjects

    [DscProperty()]
    [HashTable]$SharedNameOverrides

    AzDoServiceConnection()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoServiceConnection] Get()
    {
        return [AzDoServiceConnection]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @('ConnectionType')
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName      = $CurrentResourceObject.ProjectName
        $properties.ConnectionName   = $CurrentResourceObject.ConnectionName
        $properties.ConnectionType   = $CurrentResourceObject.ConnectionType
        $properties.Description      = $CurrentResourceObject.Description
        $properties.AllowAllPipelines = $CurrentResourceObject.AllowAllPipelines
        $properties.Authorization    = $CurrentResourceObject.Authorization
        $properties.Data             = $CurrentResourceObject.Data
        $properties.SharedWithProjects  = $CurrentResourceObject.SharedWithProjects
        $properties.SharedNameOverrides = $CurrentResourceObject.SharedNameOverrides
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure
        Write-Verbose "[AzDoServiceConnection] Current state properties: $($properties | Out-String)"
        return $properties
    }
}
