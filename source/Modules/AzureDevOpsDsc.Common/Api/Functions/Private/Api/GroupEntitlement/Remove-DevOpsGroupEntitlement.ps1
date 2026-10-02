<#
.SYNOPSIS
Deletes an Azure DevOps group entitlement (group licensing rule).

.DESCRIPTION
Removes the licensing rule. Members keep any license they hold directly; they lose only the
access level this rule granted them.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER GroupEntitlementId
The id of the group entitlement to delete.

.PARAMETER RuleOption
How existing members are treated when the rule is removed.

.EXAMPLE
Remove-DevOpsGroupEntitlement -Organization 'myorg' -GroupEntitlementId $id
#>
function Remove-DevOpsGroupEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$GroupEntitlementId,

        [Parameter()]
        [string]$RuleOption = 'applyGroupRule',

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/groupentitlements/{1}?ruleOption={2}&api-version={3}' -f
        $Organization, $GroupEntitlementId, $RuleOption, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsGroupEntitlement] Failed to delete group entitlement '$GroupEntitlementId'. Error: $_"
        return $null
    }
}
