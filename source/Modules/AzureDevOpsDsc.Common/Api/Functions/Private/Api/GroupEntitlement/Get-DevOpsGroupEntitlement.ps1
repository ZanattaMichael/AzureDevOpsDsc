<#
.SYNOPSIS
Finds an Azure DevOps group entitlement (group licensing rule) by display name.

.DESCRIPTION
Group entitlements are the licensing rules that assign an access level to every member of a
group, which is how licensing is managed at scale - AzDoUserEntitlement covers only one user at
a time.

The Member Entitlement Management API has no server-side filter for group entitlements, so the
rules are listed and matched client-side.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER GroupDisplayName
The display name of the group whose rule is wanted.

.OUTPUTS
The matching group entitlement, or $null.

.EXAMPLE
Get-DevOpsGroupEntitlement -Organization 'myorg' -GroupDisplayName 'Contoso Developers'
#>
function Get-DevOpsGroupEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$GroupDisplayName,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/groupentitlements?api-version={1}' -f $Organization, $ApiVersion

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method Get
    }
    catch
    {
        Write-Verbose "[Get-DevOpsGroupEntitlement] Group entitlement lookup failed: $_"
        return $null
    }

    $items = if ($null -ne $response.members) { $response.members } elseif ($null -ne $response.value) { $response.value } else { @($response) }

    return $items | Where-Object {
        ($_.group.displayName -eq $GroupDisplayName) -or ($_.group.principalName -eq $GroupDisplayName)
    } | Select-Object -First 1
}
