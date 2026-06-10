Function Set-DevOpsCheckConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][Object]$CheckId,
        [Parameter(Mandatory)][string]$CheckTypeId,
        [Parameter(Mandatory)][string]$CheckTypeName,
        [Parameter(Mandatory)][string]$ResourceType,
        [Parameter(Mandatory)][string]$ResourceId,
        [Parameter(Mandatory)][hashtable]$Settings,
        [Parameter()][int]$TimeoutInMinutes = 43200,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/pipelines/checks/configurations/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $CheckId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{
            id       = $CheckId
            type     = @{ id = $CheckTypeId; name = $CheckTypeName }
            settings = $Settings
            timeout  = $TimeoutInMinutes
            resource = @{
                type = $ResourceType
                id   = $ResourceId
            }
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsCheckConfiguration] Failed to update check configuration '$CheckId': $_" }
}
