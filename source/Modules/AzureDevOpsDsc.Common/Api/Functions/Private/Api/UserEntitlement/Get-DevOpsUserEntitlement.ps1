<#
.SYNOPSIS
Finds an Azure DevOps user entitlement by principal name (email / UPN).

.DESCRIPTION
Searches the Member Entitlement Management service for a user entitlement matching the supplied
principal name, using the Search User Entitlements API
(GET https://vsaex.dev.azure.com/{org}/_apis/userentitlements?$filter=name eq '...'). Returns the
single matching entitlement (which carries the entitlement id and current accessLevel) or $null.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER PrincipalName
The user's principal name (email / UPN) to search for.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.OUTPUTS
The matching user entitlement object, or $null when no user matches.

.EXAMPLE
Get-DevOpsUserEntitlement -Organization 'myorg' -PrincipalName 'jane@contoso.com'
#>
function Get-DevOpsUserEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$PrincipalName,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    # $filter is a literal OData query-parameter name; the single-quoted format string keeps PowerShell
    # from interpolating it. The filter value is URL-encoded because it contains spaces and quotes.
    $filterValue   = "name eq '$PrincipalName'"
    $encodedFilter = [uri]::EscapeDataString($filterValue)
    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/userentitlements?api-version={1}&$filter={2}' -f $Organization, $ApiVersion, $encodedFilter

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method Get
    }
    catch
    {
        # Deliberately do not log the principal name (it is PII / may be a real user).
        Write-Verbose "[Get-DevOpsUserEntitlement] User lookup failed: $_"
        return $null
    }

    # The Search response exposes the matches under 'members'; older shapes used 'value'.
    $items = if ($null -ne $response.members) { $response.members } elseif ($null -ne $response.value) { $response.value } else { @() }

    return $items | Where-Object {
        ($_.user.principalName -eq $PrincipalName) -or ($_.user.mailAddress -eq $PrincipalName)
    } | Select-Object -First 1
}
