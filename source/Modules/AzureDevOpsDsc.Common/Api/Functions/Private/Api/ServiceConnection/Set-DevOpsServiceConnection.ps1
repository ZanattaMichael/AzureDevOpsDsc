Function Set-DevOpsServiceConnection
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ServiceConnectionId,
        [Parameter(Mandatory)][string]$ServiceConnectionName,
        [Parameter(Mandatory)][string]$ServiceConnectionType,
        [Parameter()][string]$Description,
        [Parameter()][bool]$IsShared = $false,
        [Parameter()][bool]$IsReady = $true,
        [Parameter()][hashtable]$Authorization = @{},
        [Parameter()][hashtable]$Data = @{},
        # Full project reference array for an endpoint shared across projects (issue #79). See
        # New-DevOpsServiceConnection for the shape and the single-project default.
        [Parameter()][Object[]]$ProjectReferences,
        [Parameter()][string]$ApiVersion = '7.1-preview.4'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/serviceendpoint/endpoints/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ServiceConnectionId, $ApiVersion
        Method      = 'PUT'
        ContentType = 'application/json'
        Body        = @{
            id            = $ServiceConnectionId
            name          = $ServiceConnectionName
            type          = $ServiceConnectionType
            description   = $Description
            isShared      = $IsShared
            isReady       = $IsReady
            authorization = $Authorization
            data          = $Data
            serviceEndpointProjectReferences = if ($ProjectReferences) { $ProjectReferences } else {
                @(
                    @{
                        projectReference = @{ id = $ProjectId; name = $ProjectName }
                        name             = $ServiceConnectionName
                        description      = $Description
                    }
                )
            }
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsServiceConnection] Failed to update service connection '$ServiceConnectionId': $_" }
}
