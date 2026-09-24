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
    # NOTE: wrapped in @(...) - see New-DevOpsServiceConnection for why (CLAUDE.md gotcha #7:
    # a one-element array emitted from an if/else expression unrolls to a bare hashtable,
    # which ConvertTo-Json then serializes as an object instead of an array).
    $serviceEndpointProjectReferences = @(if ($ProjectReferences) { $ProjectReferences } else {
        @{
            projectReference = @{ id = $ProjectId; name = $ProjectName }
            name             = $ServiceConnectionName
            description      = $Description
        }
    })

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
            serviceEndpointProjectReferences = $serviceEndpointProjectReferences
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsServiceConnection] Failed to update service connection '$ServiceConnectionId': $_" }
}
