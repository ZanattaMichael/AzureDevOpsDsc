<#
.SYNOPSIS
Updates the access level (license) of an existing Azure DevOps user entitlement.

.DESCRIPTION
Edits a user entitlement via the Member Entitlement Management API
(PATCH https://vsaex.dev.azure.com/{org}/_apis/userentitlements/{id}) using a JSON-Patch document that
replaces the accessLevel.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER UserId
The entitlement/user id (GUID) of the user to update.

.PARAMETER AccountLicenseType
The new account license type to assign.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
Update-DevOpsUserEntitlement -Organization 'myorg' -UserId '...' -AccountLicenseType 'advanced'
#>
function Update-DevOpsUserEntitlement
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter(Mandatory = $true)]
        [string]$AccountLicenseType,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $patch = @(
        @{
            op    = 'replace'
            path  = '/accessLevel'
            value = @{
                accountLicenseType = $AccountLicenseType
                licensingSource    = 'account'
            }
        }
    )

    $params = @{
        Uri         = 'https://vsaex.dev.azure.com/{0}/_apis/userentitlements/{1}?api-version={2}' -f $Organization, $UserId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json-patch+json'
        Body        = ConvertTo-Json -InputObject $patch -Depth 5 -AsArray
    }

    if (-not $PSCmdlet.ShouldProcess($UserId, 'Update user entitlement access level'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Update-DevOpsUserEntitlement] Failed to update user '$UserId' in '$Organization': $_"
    }
}
