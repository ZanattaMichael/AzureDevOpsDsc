<#
.SYNOPSIS
Creates the pipeline authorization state for a protected Azure DevOps resource.

.DESCRIPTION
Pipeline authorization is a setting on an existing resource rather than an object with its own
create/delete lifecycle - there is nothing to "create" beyond the resource itself, which this
resource does not own. New-AzDoPipelineAuthorization therefore delegates directly to
Set-AzDoPipelineAuthorization, matching the pattern used by AzDoPipelineSettings.

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
New-AzDoPipelineAuthorization -ProjectName 'MyProject' -ResourceType 'variablegroup' -TargetResourceName 'Prod Secrets' -AuthorizedPipelines @('\Platform\deploy-infra')
#>
Function New-AzDoPipelineAuthorization
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

    Write-Verbose "[New-AzDoPipelineAuthorization] Delegating to Set-AzDoPipelineAuthorization for $ResourceType '$TargetResourceName' in project '$ProjectName'."

    Set-AzDoPipelineAuthorization @PSBoundParameters
}
