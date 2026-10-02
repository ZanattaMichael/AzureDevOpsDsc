<#
.SYNOPSIS
Updates the pipeline authorization state for a protected Azure DevOps resource.

.DESCRIPTION
PATCHes the pipelinePermissions REST API for a single resource. AllPipelinesAuthorized sets the
allPipelines.authorized flag; PipelineAuthorizations is an array of @{ id = <pipeline id>;
authorized = <bool> } entries and only needs to carry the pipelines whose authorized state is
actually changing - the API leaves every pipeline it is not told about as-is.

.PARAMETER ApiUri
The organization's base API URI, e.g. 'https://dev.azure.com/myorg'.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER ResourceType
The protected resource type: endpoint, queue, variablegroup, securefile, environment or repository.

.PARAMETER ResourceId
The resource's id as the pipelinePermissions API expects it (for 'repository',
"{projectId}.{repositoryId}").

.PARAMETER AllPipelinesAuthorized
Whether all pipelines in the project should be authorized to use the resource. Omit to leave the
existing allPipelines state untouched.

.PARAMETER PipelineAuthorizations
The per-pipeline authorization changes to apply, as an array of @{ id; authorized } hashtables.

.PARAMETER ApiVersion
The REST API version to call. Defaults to '7.1-preview.1'.

.EXAMPLE
Set-DevOpsPipelinePermission -ApiUri 'https://dev.azure.com/myorg' -ProjectName 'MyProject' -ResourceType 'variablegroup' -ResourceId '4' -AllPipelinesAuthorized $false -PipelineAuthorizations @(@{ id = 12; authorized = $true })
#>
Function Set-DevOpsPipelinePermission
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ResourceType,
        [Parameter(Mandatory)][string]$ResourceId,
        [Parameter()][System.Nullable[bool]]$AllPipelinesAuthorized,
        [Parameter()][Array]$PipelineAuthorizations,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )

    $body = @{
        resource = @{ type = $ResourceType; id = $ResourceId }
    }

    if ($null -ne $AllPipelinesAuthorized)
    {
        $body.allPipelines = @{ authorized = $AllPipelinesAuthorized }
    }

    if ($PipelineAuthorizations -and $PipelineAuthorizations.Count -gt 0)
    {
        $body.pipelines = @($PipelineAuthorizations | ForEach-Object { @{ id = $_.id; authorized = $_.authorized } })
    }

    $params = @{
        Uri         = '{0}/{1}/_apis/pipelines/pipelinePermissions/{2}/{3}?api-version={4}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ResourceType, $ResourceId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = $body | ConvertTo-Json -Depth 10
    }

    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsPipelinePermission] Failed to set pipeline permissions for $ResourceType '$ResourceId': $_" }
}
