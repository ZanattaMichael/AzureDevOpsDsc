<#
.SYNOPSIS
Removes a user from the Azure DevOps organization.

.DESCRIPTION
Resolves the user by principal name and deletes their entitlement (license, extensions and project
memberships) via the Member Entitlement Management API.

.PARAMETER UserPrincipalName
The user's principal name (email / UPN).

.PARAMETER AccountLicenseType
The account license type (informational only on removal).

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Remove-AzDoUserEntitlement
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

    Write-Verbose "[Remove-AzDoUserEntitlement] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $userId = $LookupResult.userId
    if (-not $userId)
    {
        $entitlement = Get-DevOpsUserEntitlement -Organization $OrganizationName -PrincipalName $UserPrincipalName
        if ($null -eq $entitlement)
        {
            Write-Verbose "[Remove-AzDoUserEntitlement] User not found; nothing to remove."
            return
        }
        $userId = $entitlement.id
    }

    $null = Remove-DevOpsUserEntitlement -Organization $OrganizationName -UserId $userId
}
