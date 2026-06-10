Function New-DevOpsCheckConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$CheckTypeId,
        [Parameter(Mandatory)][string]$CheckTypeName,
        [Parameter(Mandatory)][string]$ResourceType,
        [Parameter(Mandatory)][string]$ResourceId,
        [Parameter(Mandatory)][hashtable]$Settings,
        [Parameter()][int]$TimeoutInMinutes = 43200,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/pipelines/checks/configurations?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            type     = @{ id = $CheckTypeId; name = $CheckTypeName }
            settings = $Settings
            timeout  = $TimeoutInMinutes
            resource = @{
                type = $ResourceType
                id   = if ($ResourceId -match '^\d+$') { [int]$ResourceId } else { $ResourceId }
            }
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsCheckConfiguration] Failed to create check configuration: $_" }
}
