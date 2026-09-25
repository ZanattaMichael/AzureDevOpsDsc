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
        # The endpoint's existing top-level url, used when Data carries no 'url' key. The update
        # call rejects a body without one ("Value cannot be null. Parameter name: endpoint.Url").
        [Parameter()][string]$Url,
        [Parameter()][string]$ApiVersion = '7.1-preview.4'
    )
    $endpointUrl = if ($Data.url) { $Data.url } elseif ($Data.Url) { $Data.Url } elseif ($Url) { $Url } else { '' }

    # The url goes top-level only. Sending it inside 'data' as well makes the update fail with
    # AuditLogEntryContainsDuplicateDataKeyException (key=url), because the modify audit records
    # both. -ne is case-insensitive, so 'Url' is dropped too.
    $dataBody = @{}
    foreach ($key in $Data.Keys)
    {
        if ($key -ne 'url') { $dataBody[$key] = $Data[$key] }
    }

    # Same reshaping as New-DevOpsServiceConnection: the API wants credential values nested
    # under authorization.parameters, with only 'scheme' at the top level.
    if ($Authorization.Count -gt 0 -and -not $Authorization.ContainsKey('parameters'))
    {
        $scheme     = $Authorization['scheme']
        $parameters = @{}
        foreach ($key in $Authorization.Keys)
        {
            if ($key -ne 'scheme') { $parameters[$key] = $Authorization[$key] }
        }
        $Authorization = @{ scheme = $scheme; parameters = $parameters }
    }

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
            url           = $endpointUrl
            description   = $Description
            isShared      = $IsShared
            isReady       = $IsReady
            authorization = $Authorization
            data          = $dataBody
            serviceEndpointProjectReferences = $serviceEndpointProjectReferences
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsServiceConnection] Failed to update service connection '$ServiceConnectionId': $_" }
}
