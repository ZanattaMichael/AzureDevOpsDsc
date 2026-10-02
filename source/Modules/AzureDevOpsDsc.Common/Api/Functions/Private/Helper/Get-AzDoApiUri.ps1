<#
.SYNOPSIS
Resolves the base URL for an Azure DevOps REST API service.

.DESCRIPTION
Every private API function builds its request URL against one of a handful of
per-service hostnames (dev.azure.com, vssps.dev.azure.com, vsaex.dev.azure.com, and so
on). Today those hostnames are inlined at each call site. This helper centralizes that
resolution so future callers - and a future on-premise (Azure DevOps Server) code path -
have one place to change.

When -ServerUrl is not supplied, the function returns the Azure DevOps Services (cloud)
base URL for the requested -Service, built from -OrganizationName (which defaults to
Get-AzDoOrganizationName). The organization name is URL-escaped exactly once.

When -ServerUrl is supplied, it is treated as an on-premise collection URL (for example
'https://tfs.contoso.com/tfs/DefaultCollection'). Azure DevOps Server does not expose the
per-service subdomains that Azure DevOps Services uses - every service is reached through
the same collection URL - so the function returns -ServerUrl (trailing slash trimmed) for
every service that has a Server-side equivalent. Entitlements and Audit have no Server
equivalent and the function throws a terminating error naming the unsupported service.

The returned base URL never has a trailing slash, so callers can safely append
"/_apis/...".

.PARAMETER Service
The Azure DevOps REST API service to resolve a base URL for.

.PARAMETER OrganizationName
The Azure DevOps organization name (cloud only). Defaults to Get-AzDoOrganizationName.
Ignored when -ServerUrl is supplied.

.PARAMETER ServerUrl
The base collection URL of an on-premise Azure DevOps Server instance, for example
'https://tfs.contoso.com/tfs/DefaultCollection'. When supplied, must be an absolute
http or https URI.

.EXAMPLE
Get-AzDoApiUri -Service Core -OrganizationName 'contoso'
Returns 'https://dev.azure.com/contoso'.

.EXAMPLE
Get-AzDoApiUri -Service Identity -OrganizationName 'contoso'
Returns 'https://vssps.dev.azure.com/contoso'.

.EXAMPLE
Get-AzDoApiUri -Service Core -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection/'
Returns 'https://tfs.contoso.com/tfs/DefaultCollection'.

.EXAMPLE
Get-AzDoApiUri -Service Entitlements -ServerUrl 'https://tfs.contoso.com/tfs/DefaultCollection'
Throws: the Entitlements service is not supported on Azure DevOps Server.
#>
Function Get-AzDoApiUri
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Core', 'Identity', 'Entitlements', 'Feeds', 'Audit', 'Release')]
        [String]$Service,

        [Parameter(Mandatory = $false)]
        [String]$OrganizationName,

        [Parameter(Mandatory = $false)]
        [String]$ServerUrl
    )

    # Services with no Azure DevOps Server equivalent. Kept as data rather than a
    # switch-case so the "not supported" message stays consistent across services.
    $script:ServerUnsupportedServices = @('Entitlements', 'Audit')

    if (-not [String]::IsNullOrWhiteSpace($ServerUrl))
    {
        $parsedUri = $null
        $isAbsoluteUri = [System.Uri]::TryCreate($ServerUrl, [System.UriKind]::Absolute, [ref]$parsedUri)

        if (-not $isAbsoluteUri -or ($parsedUri.Scheme -ne 'http' -and $parsedUri.Scheme -ne 'https'))
        {
            throw "Get-AzDoApiUri: -ServerUrl '$ServerUrl' is not a valid absolute http or https URI."
        }

        if ($Service -in $script:ServerUnsupportedServices)
        {
            throw "Get-AzDoApiUri: the '$Service' service is not supported on Azure DevOps Server (on-premise collections have no equivalent endpoint)."
        }

        return $ServerUrl.TrimEnd('/')
    }

    if ([String]::IsNullOrWhiteSpace($OrganizationName))
    {
        $OrganizationName = Get-AzDoOrganizationName
    }

    if ([String]::IsNullOrWhiteSpace($OrganizationName))
    {
        throw 'Get-AzDoApiUri: unable to resolve an organization name. Supply -OrganizationName or set the global organization name.'
    }

    # Escape once here; never re-escape the value this function returns.
    $escapedOrganizationName = [System.Uri]::EscapeDataString($OrganizationName)

    switch ($Service)
    {
        'Core'
        {
            return "https://dev.azure.com/$escapedOrganizationName"
        }
        'Identity'
        {
            return "https://vssps.dev.azure.com/$escapedOrganizationName"
        }
        'Entitlements'
        {
            return "https://vsaex.dev.azure.com/$escapedOrganizationName"
        }
        'Feeds'
        {
            return "https://feeds.dev.azure.com/$escapedOrganizationName"
        }
        'Audit'
        {
            return "https://auditservice.dev.azure.com/$escapedOrganizationName"
        }
        'Release'
        {
            return "https://vsrm.dev.azure.com/$escapedOrganizationName"
        }
    }
}
