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
            variableGroupProjectReferences = @(
                @{ projectReference = @{ name = $ProjectName }; name = $VariableGroupName }
            )
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsVariableGroup] Failed to update variable group '$VariableGroupId': $_" }
}
