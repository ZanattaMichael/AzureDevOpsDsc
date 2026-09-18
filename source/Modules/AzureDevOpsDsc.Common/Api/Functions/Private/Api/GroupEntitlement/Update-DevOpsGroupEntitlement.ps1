<#
.SYNOPSIS
Updates the access level on an Azure DevOps group entitlement.

.DESCRIPTION
PATCHes a group licensing rule using JSON Patch, which is what this endpoint expects - unlike
most of the module's PATCH calls, which send a plain object.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER GroupEntitlementId
The id of the group entitlement to update.

.PARAMETER AccountLicenseType
The access level the rule should assign.

.PARAMETER RuleOption
How existing members are treated. 'applyGroupRule' re-applies the rule to current members.

.EXAMPLE
Update-DevOpsGroupEntitlement -Organization 'myorg' -GroupEntitlementId $id -AccountLicenseType 'stakeholder'
#>
function Update-DevOpsGroupEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$GroupEntitlementId,

        [Parameter(Mandatory = $true)]
        [string]$AccountLicenseType,

        [Parameter()]
        [string]$RuleOption = 'applyGroupRule',

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/groupentitlements/{1}?ruleOption={2}&api-version={3}' -f
        $Organization, $GroupEntitlementId, $RuleOption, $ApiVersion

    # JSON Patch, not a plain object - this endpoint rejects the latter.
    $body = @(
        @{
            op    = 'replace'
            path  = '/licenseRule'
            from  = $null
            value = @{
                licensingSource    = 'account'
                accountLicenseType = $AccountLicenseType
            }
        }
    )

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' `
            -HttpContentType 'application/json-patch+json' -Body ($body | ConvertTo-Json -Depth 6 -AsArray))
    }
    catch
    {
        Write-Error "[Update-DevOpsGroupEntitlement] Failed to update group entitlement '$GroupEntitlementId'. Error: $_"
        return $null
    }
}
