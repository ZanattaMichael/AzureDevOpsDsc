<#
.SYNOPSIS
Removes a user from an Azure DevOps organization.

.DESCRIPTION
Deletes a user entitlement via the Member Entitlement Management API
(DELETE https://vsaex.dev.azure.com/{org}/_apis/userentitlements/{id}). This unassigns the user's
license and extensions and removes them from all project memberships.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER UserId
The entitlement/user id (GUID) of the user to remove.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
Remove-DevOpsUserEntitlement -Organization 'myorg' -UserId '...'
#>
function Remove-DevOpsUserEntitlement
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $params = @{
        Uri    = 'https://vsaex.dev.azure.com/{0}/_apis/userentitlements/{1}?api-version={2}' -f $Organization, $UserId, $ApiVersion
        Method = 'DELETE'
    }

    if (-not $PSCmdlet.ShouldProcess($UserId, 'Remove user entitlement'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Remove-DevOpsUserEntitlement] Failed to remove user '$UserId' from '$Organization': $_"
    }
}
