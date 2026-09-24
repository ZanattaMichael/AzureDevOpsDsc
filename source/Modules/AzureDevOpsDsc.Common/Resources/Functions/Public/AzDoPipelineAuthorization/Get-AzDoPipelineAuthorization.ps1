<#
.SYNOPSIS
Retrieves the current pipeline authorization state for a protected Azure DevOps resource.

.DESCRIPTION
Reads the live pipelinePermissions state for a service connection, agent queue, variable group,
secure file, environment or repository, and compares it against the desired AllPipelines flag and
AuthorizedPipelines list. In additive mode (ExclusiveList = $false) the resource is Unchanged as
soon as every desired pipeline is already authorized, even if other pipelines are authorized too;
in exclusive mode, any pipeline authorized on the resource but absent from AuthorizedPipelines also
counts as drift. The live state is always read directly from the API rather than from a cache,
since pipeline authorizations are commonly changed from the Azure DevOps portal out of band.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER ResourceType
The protected resource type: endpoint, queue, variablegroup, securefile, environment or repository.

.PARAMETER ResourceName
The name of the protected resource.

.PARAMETER AuthorizedPipelines
The pipeline paths that should be authorized to use the resource.

.PARAMETER AllPipelines
Whether all pipelines in the project should be authorized to use the resource.

.PARAMETER ExclusiveList
Whether a pipeline authorized on the resource but absent from AuthorizedPipelines should be
reported as drift.

.PARAMETER LookupResult
(Optional) A hashtable to store lookup results.

.PARAMETER Ensure
(Optional) Specifies the desired state of the resource.

.PARAMETER Force
(Optional) A switch parameter to force the operation.

.OUTPUTS
System.Management.Automation.PSObject[]

.EXAMPLE
Get-AzDoPipelineAuthorization -ProjectName 'MyProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' -AuthorizedPipelines @('\Platform\deploy-infra')
#>
Function Get-AzDoPipelineAuthorization
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('endpoint', 'queue', 'variablegroup', 'securefile', 'environment', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory = $true)]
        [string]$ResourceName,

        [Parameter()]
        [string[]]$AuthorizedPipelines,

        [Parameter()]
        [bool]$AllPipelines = $false,

        [Parameter()]
        [bool]$ExclusiveList = $false,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Write-Verbose "[Get-AzDoPipelineAuthorization] Started."

    $result = @{
        Ensure            = [Ensure]::Present
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $resourceId = Resolve-AzDoPipelineAuthorizationResource -ProjectName $ProjectName -ResourceType $ResourceType -ResourceName $ResourceName

    if (-not $resourceId)
    {
        Write-Warning "[Get-AzDoPipelineAuthorization] Resource '$ResourceName' of type '$ResourceType' was not found in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = "Resource '$ResourceName' of type '$ResourceType' was not found in project '$ProjectName'."
        return $result
    }

    $result.ResourceId = $resourceId

    $OrgName = Get-AzDoOrganizationName
    try
    {
        $permission = Get-DevOpsPipelinePermission -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName -ResourceType $ResourceType -ResourceId $resourceId
    }
    catch
    {
        Write-Warning "[Get-AzDoPipelineAuthorization] Failed to retrieve pipeline permissions: $_"
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = "Failed to retrieve pipeline permissions: $_"
        return $result
    }

    $result.liveCache = $permission

    $currentAllPipelines = [bool]$permission.allPipelines.authorized
    [Array]$currentAuthorizedIds = @($permission.pipelines | Where-Object { $_.authorized } | ForEach-Object { $_.id })

    # Resolve the desired pipeline paths to ids so they can be compared against the ids the API
    # returns. An unresolved path is drift that Set can never satisfy, not something to skip.
    [Array]$desiredTargets = @()
    if ($AuthorizedPipelines)
    {
        $desiredTargets = @(Resolve-AzDoPipelineAuthorizationTargets -ProjectName $ProjectName -PipelinePaths $AuthorizedPipelines)
    }
    $result.DesiredTargets = $desiredTargets

    $unresolved = @($desiredTargets | Where-Object { -not $_.Id })
    if ($unresolved.Count -gt 0)
    {
        $unresolvedPaths = ($unresolved | ForEach-Object { $_.Path }) -join ', '
        Write-Warning "[Get-AzDoPipelineAuthorization] Could not resolve pipeline path(s): $unresolvedPaths"
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = "Could not resolve pipeline path(s): $unresolvedPaths"
        return $result
    }

    [Array]$desiredIds = @($desiredTargets | ForEach-Object { $_.Id })

    $propertiesChanged = [System.Collections.Generic.List[string]]::new()

    if ($currentAllPipelines -ne $AllPipelines)
    {
        $propertiesChanged.Add('AllPipelines')
    }

    $missing = @($desiredIds | Where-Object { $currentAuthorizedIds -notcontains $_ })
    if ($missing.Count -gt 0)
    {
        $propertiesChanged.Add('AuthorizedPipelines')
    }

    if ($ExclusiveList -and -not $propertiesChanged.Contains('AuthorizedPipelines'))
    {
        $extra = @($currentAuthorizedIds | Where-Object { $desiredIds -notcontains $_ })
        if ($extra.Count -gt 0)
        {
            $propertiesChanged.Add('AuthorizedPipelines')
        }
    }

    $result.propertiesChanged = $propertiesChanged.ToArray()
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoPipelineAuthorization] Result status: $($result.status)"

    return $result
}
