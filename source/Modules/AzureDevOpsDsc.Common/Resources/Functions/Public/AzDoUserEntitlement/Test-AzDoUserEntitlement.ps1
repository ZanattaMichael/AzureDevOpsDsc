<#
.SYNOPSIS
Placeholder test function for the AzDoUserEntitlement resource.

.DESCRIPTION
Test() is implemented by the AzDevOpsDscResourceBase base class, which compares the desired state against
the result of Get-AzDoUserEntitlement. This function exists only to satisfy the resource function naming
convention and should not be invoked directly.

.PARAMETER UserPrincipalName
The user's principal name (email / UPN).

.PARAMETER AccountLicenseType
The account license type.

.PARAMETER LookupResult
A hashtable containing the lookup result.

.PARAMETER Ensure
Specifies the desired state.

.PARAMETER Force
Forces the operation without prompting for confirmation.
#>
function Test-AzDoUserEntitlement
{
    [CmdletBinding()]
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

    # Should not be triggered. This is a placeholder for the test function.
}
