<#
.SYNOPSIS
Applies the desired pipeline authorization state to a protected Azure DevOps resource.

.DESCRIPTION
Authorizes every pipeline in AuthorizedPipelines that is not already authorized, and sets
allPipelines.authorized to AllPipelines. When ExclusiveList is $true, a pipeline currently
authorized on the resource but absent from AuthorizedPipelines is revoked, so the resource ends up
carrying exactly the configuration's list; when $false (the default) other pipelines already
authorized in the portal are left untouched. Re-resolves the resource id and current permissions
itself rather than trusting LookupResult, so it behaves the same whether it is called by the DSC
base class after Get or directly (as from a unit test).

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER ResourceType
The protected resource type: endpoint, queue, variablegroup, securefile, environment or repository.

.PARAMETER TargetResourceName
The name of the protected resource.

.PARAMETER AuthorizedPipelines
The pipeline paths that should be authorized to use the resource.

.PARAMETER AllPipelines
Whether all pipelines in the project should be authorized to use the resource.

.PARAMETER ExclusiveList
Whether a pipeline authorized on the resource but absent from AuthorizedPipelines should be
revoked.

.PARAMETER LookupResult
(Optional) A hashtable containing the lookup result from Get.

.PARAMETER Ensure
(Optional) Specifies the desired state of the resource.

.PARAMETER Force
(Optional) A switch parameter to force the operation.

.EXAMPLE
Set-AzDoPipelineAuthorization -ProjectName 'MyProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' -AllPipelines $false -AuthorizedPipelines @('\Platform\deploy-infra') -ExclusiveList $true
#>
Function Set-AzDoPipelineAuthorization
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('endpoint', 'queue', 'variablegroup', 'securefile', 'environment', 'repository')]
        [string]$ResourceType,

        [Parameter(Mandatory = $true)]
        [string]$TargetResourceName,

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

    Write-Verbose "[Set-AzDoPipelineAuthorization] Updating pipeline authorization for $ResourceType '$TargetResourceName' in project '$ProjectName'."

    $resourceId = Resolve-AzDoPipelineAuthorizationResource -ProjectName $ProjectName -ResourceType $ResourceType -TargetResourceName $TargetResourceName
    if (-not $resourceId)
    {
        Write-Error "[Set-AzDoPipelineAuthorization] Resource '$TargetResourceName' of type '$ResourceType' was not found in project '$ProjectName'."
        return
    }

    $OrgName = Get-AzDoOrganizationName
    $ApiUri  = "https://dev.azure.com/$OrgName"

    $current = Get-DevOpsPipelinePermission -ApiUri $ApiUri -ProjectName $ProjectName -ResourceType $ResourceType -ResourceId $resourceId
    [Array]$currentAuthorizedIds = @($current.pipelines | Where-Object { $_.authorized } | ForEach-Object { $_.id })

    [Array]$desiredTargets = @()
    if ($AuthorizedPipelines)
    {
        $desiredTargets = @(Resolve-AzDoPipelineAuthorizationTargets -ProjectName $ProjectName -PipelinePaths $AuthorizedPipelines)
    }

    $unresolved = @($desiredTargets | Where-Object { -not $_.Id })
    if ($unresolved.Count -gt 0)
    {
        $unresolvedPaths = ($unresolved | ForEach-Object { $_.Path }) -join ', '
        Write-Error "[Set-AzDoPipelineAuthorization] Could not resolve pipeline path(s): $unresolvedPaths"
        return
    }

    [Array]$desiredIds = @($desiredTargets | ForEach-Object { $_.Id })

    $authorizations = [System.Collections.Generic.List[Hashtable]]::new()

    foreach ($id in $desiredIds)
    {
        if ($currentAuthorizedIds -notcontains $id)
        {
            $authorizations.Add(@{ id = $id; authorized = $true })
        }
    }

    if ($ExclusiveList)
    {
        foreach ($id in $currentAuthorizedIds)
        {
            if ($desiredIds -notcontains $id)
            {
                $authorizations.Add(@{ id = $id; authorized = $false })
            }
        }
    }

    $params = @{
        ApiUri                 = $ApiUri
        ProjectName            = $ProjectName
        ResourceType           = $ResourceType
        ResourceId             = $resourceId
        AllPipelinesAuthorized = $AllPipelines
    }
    if ($authorizations.Count -gt 0) { $params.PipelineAuthorizations = $authorizations.ToArray() }

    $value = Set-DevOpsPipelinePermission @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoPipelineAuthorization] Set-DevOpsPipelinePermission returned null. Check authentication token and organization settings."
        return
    }

    $cacheKey = '{0}\{1}\{2}' -f $ProjectName, $ResourceType, $TargetResourceName
    Add-CacheItem -Key $cacheKey -Value $value -Type 'LivePipelineAuthorizations' -SuppressWarning
    Export-CacheObject -CacheType 'LivePipelineAuthorizations' -Content $AzDoLivePipelineAuthorizations
}
