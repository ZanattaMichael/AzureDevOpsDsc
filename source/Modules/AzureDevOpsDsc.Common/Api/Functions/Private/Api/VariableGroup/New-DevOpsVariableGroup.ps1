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
        # Full project reference array for a group shared across projects (issue #79). Each entry
        # is @{ projectReference = @{ id; name }; name; description }. Defaults to a single
        # reference for the owning project - the shape this function always sent before sharing
        # support existed - when the caller has no sharing to configure.
        [Parameter()][Object[]]$ProjectReferences,
        [Parameter()][string]$ApiVersion = '7.1-preview.2'
    )
    $variableGroupProjectReferences = if ($ProjectReferences) { $ProjectReferences } else {
        @( @{ projectReference = @{ name = $ProjectName }; name = $VariableGroupName } )
    }
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/variablegroups?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name        = $VariableGroupName
            description = $Description
            type        = $Type
            variables   = $Variables
            variableGroupProjectReferences = $variableGroupProjectReferences
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsVariableGroup] Failed to create variable group '$VariableGroupName': $_" }
}
