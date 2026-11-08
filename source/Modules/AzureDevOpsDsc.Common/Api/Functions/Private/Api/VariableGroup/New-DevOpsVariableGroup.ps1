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
    # Accept both @{ NAME = 'value' } and @{ NAME = @{ value = 'v'; isSecret = $true } }; the API
    # stores only the latter shape, and a secret is only secret when 'isSecret' reaches it.
    $normalizedVariables = ConvertTo-AzDoVariableGroupVariables -Variables $Variables

    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/variablegroups?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name        = $VariableGroupName
            description = $Description
            type        = $Type
            variables   = $normalizedVariables
            # The description Azure DevOps shows and returns for a project is the one on the
            # project reference; the top-level one alone is not stored, and a group written
            # without it reads back with a null description.
            variableGroupProjectReferences = @(
                @{
                    projectReference = @{ name = $ProjectName }
                    name             = $VariableGroupName
                    description      = $Description
                }
            )
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsVariableGroup] Failed to create variable group '$VariableGroupName': $_" }
}
