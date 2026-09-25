<#
.SYNOPSIS
Shares an existing service connection with additional projects.

.DESCRIPTION
The service connection update call (PUT) only edits the project references an endpoint already
has; it does not share the endpoint with a new project. Sharing goes through the dedicated
"Share Service Endpoint" call instead:

  PATCH {org}/_apis/serviceendpoint/endpoints/{endpointId}?api-version=7.1-preview.4

whose request body is an array of ServiceEndpointProjectReference entries - one per project to
share with, each carrying the name (and description) the endpoint should have in that project.
Only the projects being added are sent; unsharing is a separate DELETE call
(Remove-DevOpsServiceConnection with the project's id).

.PARAMETER ApiUri
The base organization API URI, e.g. 'https://dev.azure.com/myorg/'.

.PARAMETER ServiceConnectionId
The id of the service connection to share.

.PARAMETER ProjectReferences
The @{ projectReference = @{ id; name }; name; description } entries for the projects to share
the service connection with.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1-preview.4'.

.EXAMPLE
Add-DevOpsServiceConnectionProjectReferences -ApiUri $orgApiUri -ServiceConnectionId $sc.id -ProjectReferences $addedRefs
#>
Function Add-DevOpsServiceConnectionProjectReferences
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ServiceConnectionId,
        [Parameter(Mandatory)][Object[]]$ProjectReferences,
        [Parameter()][string]$ApiVersion = '7.1-preview.4'
    )
    $params = @{
        Uri         = '{0}/_apis/serviceendpoint/endpoints/{1}?api-version={2}' -f $ApiUri.TrimEnd('/'), $ServiceConnectionId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        # -AsArray keeps a single reference as a JSON array (CLAUDE.md gotcha #7); the API
        # requires an array here even when sharing with one project.
        Body        = $ProjectReferences | ConvertTo-Json -Depth 10 -AsArray
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Add-DevOpsServiceConnectionProjectReferences] Failed to share service connection '$ServiceConnectionId': $_" }
}
