<#
.SYNOPSIS
Retrieves the pipeline authorization state for a protected Azure DevOps resource.

.DESCRIPTION
Calls the pipelinePermissions REST API for a single resource, returning its allPipelines flag and
the per-pipeline authorization list. A resource that has never had its pipeline permissions touched
returns a valid response with an empty/absent pipelines list rather than a 404, since "no explicit
authorizations yet" is itself a real state.

.PARAMETER ApiUri
The organization's base API URI, e.g. 'https://dev.azure.com/myorg'.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER ResourceType
The protected resource type: endpoint, queue, variablegroup, securefile, environment or repository.

.PARAMETER ResourceId
The resource's id as the pipelinePermissions API expects it (for 'repository',
"{projectId}.{repositoryId}").

.PARAMETER ApiVersion
The REST API version to call. Defaults to '7.1-preview.1'.

.EXAMPLE
Get-DevOpsPipelinePermission -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'MyProject' -ResourceType 'variablegroup' -ResourceId '4'
#>
Function Get-DevOpsPipelinePermission
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ResourceType,
        [Parameter(Mandatory)][string]$ResourceId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )

    $params = @{
        Uri    = '{0}/{1}/_apis/pipelines/pipelinePermissions/{2}/{3}?api-version={4}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ResourceType, $ResourceId, $ApiVersion
        Method = 'GET'
    }

    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Get-DevOpsPipelinePermission] Failed to get pipeline permissions for $ResourceType '$ResourceId': $_" }
}
