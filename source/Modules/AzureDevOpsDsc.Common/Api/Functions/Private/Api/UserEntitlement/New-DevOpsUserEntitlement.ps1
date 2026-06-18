<#
.SYNOPSIS
Adds a user to an Azure DevOps organization and assigns an access level (license).

.DESCRIPTION
Creates a user entitlement via the Member Entitlement Management API
(POST https://vsaex.dev.azure.com/{org}/_apis/userentitlements). The user is identified by principal
name and assigned the given account license type.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER PrincipalName
The user's principal name (email / UPN).

.PARAMETER AccountLicenseType
The account license type to assign (e.g. stakeholder, express, advanced, professional, none).

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
New-DevOpsUserEntitlement -Organization 'myorg' -PrincipalName 'jane@contoso.com' -AccountLicenseType 'express'
#>
function New-DevOpsUserEntitlement
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$PrincipalName,

        [Parameter(Mandatory = $true)]
        [string]$AccountLicenseType,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $body = @{
        accessLevel = @{
            licensingSource    = 'account'
            accountLicenseType = $AccountLicenseType
        }
        user = @{
            principalName = $PrincipalName
            subjectKind   = 'user'
        }
    }

    $params = @{
        Uri    = 'https://vsaex.dev.azure.com/{0}/_apis/userentitlements?api-version={1}' -f $Organization, $ApiVersion
        Method = 'POST'
        Body   = $body | ConvertTo-Json -Depth 5
    }

    if (-not $PSCmdlet.ShouldProcess($PrincipalName, 'Add user entitlement'))
    {
        return
    }

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[New-DevOpsUserEntitlement] Failed to add user '$PrincipalName' to '$Organization': $_"
    }

    # The Add API returns 200 with an operationResult that reports per-user success/failure.
    if ($null -ne $response.operationResult -and -not $response.operationResult.isSuccess)
    {
        $errText = ($response.operationResult.errors | ForEach-Object { $_.value }) -join '; '
        throw "[New-DevOpsUserEntitlement] Failed to add user '$PrincipalName': $errText"
    }

    return $response
}
