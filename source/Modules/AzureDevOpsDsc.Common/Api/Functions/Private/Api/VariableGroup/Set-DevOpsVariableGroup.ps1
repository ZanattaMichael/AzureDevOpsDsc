Function Set-DevOpsVariableGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][Object]$VariableGroupId,
        [Parameter(Mandatory)][string]$VariableGroupName,
        [Parameter()][string]$Description,
        [Parameter()][ValidateSet('Vsts','AzureKeyVault')][string]$Type = 'Vsts',
        [Parameter()][HashTable]$Variables = @{},
        # Full project reference array for a group shared across projects (issue #79). See
        # New-DevOpsVariableGroup for the shape and the single-project default.
        [Parameter()][Object[]]$ProjectReferences,
        [Parameter()][string]$ApiVersion = '7.1-preview.2'
    )
    # NOTE: wrapped in @(...) - see New-DevOpsVariableGroup for why (CLAUDE.md gotcha #7:
    # a one-element array emitted from an if/else expression unrolls to a bare hashtable,
    # which ConvertTo-Json then serializes as an object instead of an array).
    $variableGroupProjectReferences = @(if ($ProjectReferences) { $ProjectReferences } else {
        @{ projectReference = @{ name = $ProjectName }; name = $VariableGroupName }
    })
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/variablegroups/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $VariableGroupId, $ApiVersion
        Method      = 'PUT'
        ContentType = 'application/json'
        Body        = @{
            id          = $VariableGroupId
            name        = $VariableGroupName
            description = $Description
            type        = $Type
            variables   = $Variables
            variableGroupProjectReferences = $variableGroupProjectReferences
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsVariableGroup] Failed to update variable group '$VariableGroupId': $_" }
}
