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
        # Full project reference array for an endpoint shared across projects (issue #79). Each
        # entry is @{ projectReference = @{ id; name }; name; description }. Defaults to a single
        # reference for the owning project - the shape this function always sent before sharing
        # support existed - when the caller has no sharing to configure.
        [Parameter()][Object[]]$ProjectReferences,
        [Parameter()][string]$ApiVersion = '7.1-preview.4'
    )
    # The Azure DevOps service endpoint API requires 'url' at the top-level body,
    # not nested inside 'data'. Callers may supply it via Data.url as a convenience.
    $endpointUrl = if ($Data.url) { $Data.url } elseif ($Data.Url) { $Data.Url } else { '' }

    # Once lifted, 'url' must not also be sent inside 'data': that accepts only the inputs the
    # connection type declares, and rejects the request with
    # "Following fields in the service connection are not expected: url".
    $endpointData = @{}
    foreach ($key in $Data.Keys)
    {
        if ($key -ne 'url') { $endpointData[$key] = $Data[$key] }
    }

    # The endpoint API expects the credential values nested under Authorization.parameters,
    # with only 'scheme' at the top level. Callers may pass the credential values flat
    # (e.g. @{ scheme = 'UsernamePassword'; username = 'x'; password = 'y' }) for convenience;
    # an empty/missing 'parameters' is rejected with
    # "The collection must contain at least one element. Parameter name: endpoint.Authorization.Parameters".
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

    # NOTE: the if/else is wrapped in @(...) because PowerShell unrolls a one-element array
    # emitted from an if/else expression the same way it unrolls a one-element array returned
    # from a function (CLAUDE.md gotcha #7). Without the outer @(), a single project reference
    # collapses to a bare hashtable and ConvertTo-Json writes a JSON object instead of an array,
    # which the API rejects ("At least one project reference required to create an endpoint").
    $serviceEndpointProjectReferences = @(if ($ProjectReferences) { $ProjectReferences } else {
        @{
            projectReference = @{ id = $ProjectId; name = $ProjectName }
            name             = $ServiceConnectionName
            description      = $Description
        }
    })

    $params = @{
        Uri         = '{0}/{1}/_apis/serviceendpoint/endpoints?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name          = $ServiceConnectionName
            type          = $ServiceConnectionType
            url           = $endpointUrl
            description   = $Description
            isShared      = $IsShared
            isReady       = $IsReady
            authorization = $Authorization
            data          = $endpointData
            serviceEndpointProjectReferences = $serviceEndpointProjectReferences
        } | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsServiceConnection] Failed to create service connection '$ServiceConnectionName': $_" }
}
