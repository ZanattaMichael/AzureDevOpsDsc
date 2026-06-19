<#
.SYNOPSIS
Updates the access level of an existing Azure DevOps user entitlement.

.DESCRIPTION
Resolves the user by principal name and updates their account license type via the Member Entitlement
Management API.

.PARAMETER UserPrincipalName
The user's principal name (email / UPN).

.PARAMETER AccountLicenseType
The desired account license type.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Set-AzDoUserEntitlement
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('PrincipalName')]
        [System.String]$UserPrincipalName,

        [Parameter()]
        [System.String]$AccountLicenseType,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoUserEntitlement] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    # Prefer the id resolved by Get; fall back to a live lookup.
    $userId = $LookupResult.userId
    if (-not $userId)
    {
        $entitlement = Get-DevOpsUserEntitlement -Organization $OrganizationName -PrincipalName $UserPrincipalName
        if ($null -eq $entitlement)
        {
            throw "[Set-AzDoUserEntitlement] User not found; cannot update."
        }
        $userId = $entitlement.id
    }

    $params = @{
        Organization       = $OrganizationName
        UserId             = $userId
        AccountLicenseType = $AccountLicenseType
    }

    $null = Update-DevOpsUserEntitlement @params
}
