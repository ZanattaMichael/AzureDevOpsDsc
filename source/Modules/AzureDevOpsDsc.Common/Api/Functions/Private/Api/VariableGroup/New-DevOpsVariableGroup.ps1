Function New-DevOpsVariableGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$VariableGroupName,
        [Parameter()][string]$Description,
        [Parameter()][ValidateSet('Vsts','AzureKeyVault')][string]$Type = 'Vsts',
        [Parameter()][HashTable]$Variables = @{},
        [Parameter()][bool]$AllowAccess = $false,
        [Parameter()][string]$ApiVersion = '7.1-preview.2'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/variablegroups?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
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
    catch { Throw "[New-DevOpsVariableGroup] Failed to create variable group '$VariableGroupName': $_" }
}
