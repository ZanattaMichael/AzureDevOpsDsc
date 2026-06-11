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
    # The Azure DevOps service endpoint API requires 'url' at the top-level body,
    # not nested inside 'data'. Callers may supply it via Data.url as a convenience.
    $endpointUrl = if ($Data.url) { $Data.url } elseif ($Data.Url) { $Data.Url } else { '' }

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
