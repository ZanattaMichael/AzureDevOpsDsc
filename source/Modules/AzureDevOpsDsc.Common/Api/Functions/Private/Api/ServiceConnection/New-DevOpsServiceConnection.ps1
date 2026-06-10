Function New-DevOpsServiceConnection
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ServiceConnectionName,
        [Parameter(Mandatory)][string]$ServiceConnectionType,
        [Parameter()][string]$Description,
        [Parameter()][bool]$IsShared = $false,
        [Parameter()][bool]$IsReady = $true,
        [Parameter()][hashtable]$Authorization = @{},
        [Parameter()][hashtable]$Data = @{},
        [Parameter()][string]$ApiVersion = '7.1-preview.4'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/serviceendpoint/endpoints?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name          = $ServiceConnectionName
            type          = $ServiceConnectionType
            description   = $Description
            isShared      = $IsShared
            isReady       = $IsReady
            authorization = $Authorization
            data          = $Data
            serviceEndpointProjectReferences = @(
                @{
                    projectReference = @{ id = $ProjectId; name = $ProjectName }
                    name             = $ServiceConnectionName
                    description      = $Description
                }
            )
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsServiceConnection] Failed to create service connection '$ServiceConnectionName': $_" }
}
