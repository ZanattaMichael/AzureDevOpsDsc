<#
.SYNOPSIS
Removes the pipeline authorization state a configuration declared for a protected Azure DevOps
resource.

.DESCRIPTION
There is no "delete" for a resource's pipeline permissions - the resource itself is unaffected and
some authorization state always exists. Ensure = 'Absent' is therefore treated conservatively: only
the pipelines this configuration itself listed in AuthorizedPipelines are revoked, and
allPipelines.authorized is reset to $false (the secure default), regardless of ExclusiveList. A
pipeline authorized on the resource that this configuration never declared is left untouched,
since Ensure = 'Absent' here means "stop managing what I asked for", not "wipe every authorization
on the resource".

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER ResourceType
The protected resource type: endpoint, queue, variablegroup, securefile, environment or repository.

.PARAMETER ResourceName
The name of the protected resource.

.PARAMETER AuthorizedPipelines
The pipeline paths this configuration declared; each is revoked.

.PARAMETER AllPipelines
Unused for removal - allPipelines.authorized is always reset to $false.

.PARAMETER ExclusiveList
Unused for removal - only the pipelines this configuration declared are revoked.

.PARAMETER LookupResult
(Optional) A hashtable containing the lookup result from Get.

.PARAMETER Ensure
(Optional) Specifies the desired state of the resource.

.PARAMETER Force
(Optional) A switch parameter to force the operation.

.EXAMPLE
Remove-AzDoPipelineAuthorization -ProjectName 'MyProject' -ResourceType 'variablegroup' -ResourceName 'Prod Secrets' -AuthorizedPipelines @('\Platform\deploy-infra')
#>
Function Remove-AzDoPipelineAuthorization
{
    [CmdletBinding(SupportsShouldProcess = $true)]
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

    Write-Verbose "[Remove-AzDoPipelineAuthorization] Revoking declared pipeline authorization for $ResourceType '$ResourceName' in project '$ProjectName'."

    $resourceId = Resolve-AzDoPipelineAuthorizationResource -ProjectName $ProjectName -ResourceType $ResourceType -ResourceName $ResourceName
    if (-not $resourceId)
    {
        Write-Error "[Remove-AzDoPipelineAuthorization] Resource '$ResourceName' of type '$ResourceType' was not found in project '$ProjectName'."
        return
    }

    $OrgName = Get-AzDoOrganizationName
    $ApiUri  = "https://dev.azure.com/$OrgName"

    $authorizations = [System.Collections.Generic.List[Hashtable]]::new()

    if ($AuthorizedPipelines)
    {
        [Array]$targets = @(Resolve-AzDoPipelineAuthorizationTargets -ProjectName $ProjectName -PipelinePaths $AuthorizedPipelines)
        foreach ($target in $targets)
        {
            if ($target.Id)
            {
                $authorizations.Add(@{ id = $target.Id; authorized = $false })
            }
            else
            {
                Write-Warning "[Remove-AzDoPipelineAuthorization] Could not resolve pipeline path '$($target.Path)' - skipping its revocation."
            }
        }
    }

    $params = @{
        ApiUri                 = $ApiUri
        ProjectName            = $ProjectName
        ResourceType           = $ResourceType
        ResourceId             = $resourceId
        AllPipelinesAuthorized = $false
    }
    if ($authorizations.Count -gt 0) { $params.PipelineAuthorizations = $authorizations.ToArray() }

    $value = Set-DevOpsPipelinePermission @params

    if ($null -eq $value)
    {
        Write-Error "[Remove-AzDoPipelineAuthorization] Set-DevOpsPipelinePermission returned null. Check authentication token and organization settings."
        return
    }

    $cacheKey = '{0}\{1}\{2}' -f $ProjectName, $ResourceType, $ResourceName
    Remove-CacheItem -Key $cacheKey -Type 'LivePipelineAuthorizations'
    Export-CacheObject -CacheType 'LivePipelineAuthorizations' -Content $AzDoLivePipelineAuthorizations
}
