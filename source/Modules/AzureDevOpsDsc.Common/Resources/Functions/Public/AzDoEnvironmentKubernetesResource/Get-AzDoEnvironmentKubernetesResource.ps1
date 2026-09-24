<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps environment Kubernetes resource.

.DESCRIPTION
Resolves the parent pipeline environment and the service connection by name, then looks the
Kubernetes resource up by name within that environment and compares it against the desired
state. Tags are compared case-insensitively as a set, and only when the configuration actually
specifies Tags.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER EnvironmentName
The name of the pipeline environment the resource belongs to.

.PARAMETER KubernetesResourceName
The name of the Kubernetes resource within the environment.

.PARAMETER Namespace
The Kubernetes namespace the resource addresses.

.PARAMETER ClusterName
An optional display name for the cluster.

.PARAMETER ServiceConnectionName
The name of the service connection used to reach the cluster.

.PARAMETER Tags
Tags applied to the resource.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoEnvironmentKubernetesResource -ProjectName 'Contoso' -EnvironmentName 'Production' -KubernetesResourceName 'prod-namespace' -Namespace 'prod' -ServiceConnectionName 'prod-k8s-connection'
#>
Function Get-AzDoEnvironmentKubernetesResource
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$EnvironmentName,

        [Parameter(Mandatory = $true)]
        [System.String]$KubernetesResourceName,

        [Parameter()]
        [System.String]$Namespace,

        [Parameter()]
        [System.String]$ClusterName,

        [Parameter()]
        [System.String]$ServiceConnectionName,

        [Parameter()]
        [System.String[]]$Tags,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoEnvironmentKubernetesResource] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $organization = Get-AzDoOrganizationName

    # Resolve the parent environment.
    $envCacheKey = '{0}\{1}' -f $ProjectName, $EnvironmentName
    $environment = Get-CacheItem -Key $envCacheKey -Type 'LivePipelineEnvironments'
    if (-not $environment)
    {
        $allEnvironments = List-DevOpsPipelineEnvironments -ApiUri "https://dev.azure.com/$organization" -ProjectName $ProjectName
        $environment     = $allEnvironments | Where-Object { $_.name -eq $EnvironmentName } | Select-Object -First 1
        if ($environment) { Add-CacheItem -Key $envCacheKey -Value $environment -Type 'LivePipelineEnvironments' }
    }

    if ($null -eq $environment)
    {
        Write-Verbose "[Get-AzDoEnvironmentKubernetesResource] Environment '$EnvironmentName' was not found in project '$ProjectName'."
        # Nothing can be registered under a parent that does not exist, so Absent already holds.
        # The base class treats only 'NotFound' as "nothing to do" for Absent.
        if ($Ensure -eq [Ensure]::Absent)
        {
            $result.status = [DSCGetSummaryState]::NotFound
            return $result
        }

        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EnvironmentNotFound'
        return $result
    }

    $result.environmentId = $environment.id

    # Resolve the service connection.
    $scCacheKey       = '{0}\{1}' -f $ProjectName, $ServiceConnectionName
    $serviceConnection = Get-CacheItem -Key $scCacheKey -Type 'LiveServiceConnections'
    if (-not $serviceConnection)
    {
        $allConnections    = List-DevOpsServiceConnections -ApiUri "https://dev.azure.com/$organization" -ProjectName $ProjectName
        $serviceConnection = $allConnections | Where-Object { $_.name -eq $ServiceConnectionName } | Select-Object -First 1
        if ($serviceConnection) { Add-CacheItem -Key $scCacheKey -Value $serviceConnection -Type 'LiveServiceConnections' }
    }

    if ($null -eq $serviceConnection)
    {
        Write-Verbose "[Get-AzDoEnvironmentKubernetesResource] Service connection '$ServiceConnectionName' was not found in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'ServiceConnectionNotFound'
        return $result
    }

    $result.serviceEndpointId = $serviceConnection.id

    $resources = List-DevOpsEnvironmentKubernetesResources -Organization $organization -ProjectName $ProjectName -EnvironmentId $environment.id
    $resource  = $resources | Where-Object { $_.name -eq $KubernetesResourceName } | Select-Object -First 1

    if ($null -eq $resource)
    {
        Write-Verbose "[Get-AzDoEnvironmentKubernetesResource] Kubernetes resource '$KubernetesResourceName' does not exist on environment '$EnvironmentName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $resource
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('Namespace') -and ("$($resource.namespace)" -ne "$Namespace"))
    {
        $propertiesChanged += 'Namespace'
    }

    if ($PSBoundParameters.ContainsKey('ClusterName') -and ("$($resource.clusterName)" -ne "$ClusterName"))
    {
        $propertiesChanged += 'ClusterName'
    }

    if ("$($resource.serviceEndpointId)" -ne "$($serviceConnection.id)")
    {
        $propertiesChanged += 'ServiceConnectionName'
    }

    # Tags are compared case-insensitively as a set, and only when the configuration specifies
    # Tags at all - an unset Tags property never reads as "must be empty".
    if ($PSBoundParameters.ContainsKey('Tags'))
    {
        $currentTags = @($resource.tags) | Where-Object { $_ }
        $desiredTags = @($Tags) | Where-Object { $_ }
        $currentSet  = [System.Collections.Generic.HashSet[string]]::new([string[]]@($currentTags | ForEach-Object { $_.ToLowerInvariant() }))
        $desiredSet  = [System.Collections.Generic.HashSet[string]]::new([string[]]@($desiredTags | ForEach-Object { $_.ToLowerInvariant() }))
        if (-not $currentSet.SetEquals($desiredSet))
        {
            Write-Verbose "[Get-AzDoEnvironmentKubernetesResource] Tags differ for Kubernetes resource '$KubernetesResourceName'. This can only be corrected by deleting and recreating the resource - its id will change."
            $propertiesChanged += 'Tags'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoEnvironmentKubernetesResource] Kubernetes resource '$KubernetesResourceName' status: $($result.status)."

    return $result
}
