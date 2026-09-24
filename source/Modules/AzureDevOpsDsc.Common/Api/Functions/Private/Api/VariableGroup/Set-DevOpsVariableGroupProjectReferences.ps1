<#
.SYNOPSIS
Shares (or unshares) a variable group across projects.

.DESCRIPTION
Azure DevOps rejects extra project references on both the create (POST) and update (PUT)
variable-group calls with "Sharing of variable group is not allowed." Cross-project sharing is
applied through a separate, project-less endpoint instead:

  PATCH {org}/_apis/distributedtask/variablegroups?variableGroupId={id}&api-version=7.1-preview.2

whose request body is the *entire* desired VariableGroupProjectReference array (not wrapped in a
container object) - each call replaces the group's whole share list, so callers must pass every
reference the group should end up with, including the owning project's.

.PARAMETER ApiUri
The base organization API URI, e.g. 'https://dev.azure.com/myorg/'.

.PARAMETER VariableGroupId
The id of the variable group to (re)share.

.PARAMETER ProjectReferences
The full desired array of @{ projectReference = @{ id; name }; name; description } entries,
including the owning project's reference.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1-preview.2'.

.EXAMPLE
Set-DevOpsVariableGroupProjectReferences -ApiUri $orgApiUri -VariableGroupId $vg.id -ProjectReferences $refs
#>
Function Set-DevOpsVariableGroupProjectReferences
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][Object]$VariableGroupId,
        [Parameter(Mandatory)][Object[]]$ProjectReferences,
        [Parameter()][string]$ApiVersion = '7.1-preview.2'
    )
    $params = @{
        Uri         = '{0}/_apis/distributedtask/variablegroups?variableGroupId={1}&api-version={2}' -f $ApiUri.TrimEnd('/'), $VariableGroupId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        # -AsArray guards against ConvertTo-Json's default behaviour of collapsing a
        # single-element collection into a bare object when it is the top-level input
        # (CLAUDE.md gotcha #7) - the API requires a JSON array here even for one reference.
        Body        = $ProjectReferences | ConvertTo-Json -Depth 10 -AsArray
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsVariableGroupProjectReferences] Failed to update project references for variable group '$VariableGroupId': $_" }
}
