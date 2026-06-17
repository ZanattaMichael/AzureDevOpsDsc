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
        [Parameter()][string]$ResourceName,
        [Parameter(Mandatory)][hashtable]$Settings,
        [Parameter()][int]$TimeoutInMinutes = 43200,
        [Parameter()][bool]$Enabled = $true,
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
            # The checks/configurations API expects 'resource.id' as a STRING. Sending it as an int
            # (and including the non-schema top-level 'enabled' field) produced a server-side
            # InvalidCheckConfigurationException: "Object reference not set". The working Approval
            # check (New-DevOpsEnvironmentApproval) sends a string id and no 'enabled'.
            resource = @{
                type = $ResourceType
                id   = [string]$ResourceId
            }
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsCheckConfiguration] Failed to create check configuration: $_" }
}
