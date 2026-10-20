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
        [Parameter()][string]$ApiVersion = '7.1-preview.2'
    )
    # Accept both @{ NAME = 'value' } and @{ NAME = @{ value = 'v'; isSecret = $true } }; the API
    # stores only the latter shape, and a secret is only secret when 'isSecret' reaches it.
    $normalizedVariables = ConvertTo-AzDoVariableGroupVariables -Variables $Variables

    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/variablegroups/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $VariableGroupId, $ApiVersion
        Method      = 'PUT'
        ContentType = 'application/json'
        Body        = @{
            id          = $VariableGroupId
            name        = $VariableGroupName
            description = $Description
            type        = $Type
            variables   = $normalizedVariables
            variableGroupProjectReferences = @(
                @{ projectReference = @{ name = $ProjectName }; name = $VariableGroupName }
            )
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsVariableGroup] Failed to update variable group '$VariableGroupId': $_" }
}
