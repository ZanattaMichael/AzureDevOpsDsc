<#
.SYNOPSIS
Adds a user to the Azure DevOps organization with the desired access level.

.DESCRIPTION
Creates a user entitlement (adds the user and assigns an account license) via the Member Entitlement
Management API.

.PARAMETER UserPrincipalName
The user's principal name (email / UPN).

.PARAMETER AccountLicenseType
The account license type to assign.

.PARAMETER LookupResult
A hashtable containing the lookup result from Get.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function New-AzDoUserEntitlement
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

    Write-Verbose "[New-AzDoUserEntitlement] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    if ([string]::IsNullOrWhiteSpace($AccountLicenseType))
    {
        throw "[New-AzDoUserEntitlement] AccountLicenseType is required to add user '$UserPrincipalName'."
    }

    $params = @{
        Organization       = $OrganizationName
        PrincipalName      = $UserPrincipalName
        AccountLicenseType = $AccountLicenseType
    }

    $null = New-DevOpsUserEntitlement @params
}
