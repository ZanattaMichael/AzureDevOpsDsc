<#
.SYNOPSIS
Builds a service hook subscription request body from resource properties.

.DESCRIPTION
Assembles the subscription hashtable sent to the Service Hooks API. When a ProjectName is supplied its
project id is resolved (cache-first, then a live lookup) and added to the publisher inputs as 'projectId'.

.PARAMETER OrganizationName
The name of the Azure DevOps organization (used to resolve the project id).

.PARAMETER PublisherId
The publisher id.

.PARAMETER EventType
The event type.

.PARAMETER ConsumerId
The consumer id.

.PARAMETER ConsumerActionId
The consumer action id.

.PARAMETER ConsumerInputs
The consumer input values.

.PARAMETER PublisherInputs
The publisher input values.

.PARAMETER ResourceVersion
The event resource version.

.PARAMETER ProjectName
Optional project name to resolve into a 'projectId' publisher input.

.OUTPUTS
A hashtable suitable for the Service Hooks create/replace body.
#>
function ConvertTo-DevOpsServiceHookSubscription
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [string]$PublisherId,

        [Parameter(Mandatory = $true)]
        [string]$EventType,

        [Parameter(Mandatory = $true)]
        [string]$ConsumerId,

        [Parameter(Mandatory = $true)]
        [string]$ConsumerActionId,

        [Parameter()]
        [hashtable]$ConsumerInputs = @{},

        [Parameter()]
        [hashtable]$PublisherInputs = @{},

        [Parameter()]
        [string]$ResourceVersion = '1.0',

        [Parameter()]
        [string]$ProjectName
    )

    $pubInputs = @{}
    foreach ($key in $PublisherInputs.Keys) { $pubInputs[$key] = $PublisherInputs[$key] }

    if (-not [string]::IsNullOrWhiteSpace($ProjectName))
    {
        $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
        if (-not $project)
        {
            $project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        }
        if ($project.id) { $pubInputs['projectId'] = $project.id }
    }

    return @{
        publisherId      = $PublisherId
        eventType        = $EventType
        resourceVersion  = $ResourceVersion
        consumerId       = $ConsumerId
        consumerActionId = $ConsumerActionId
        publisherInputs  = $pubInputs
        consumerInputs   = $ConsumerInputs
    }
}
