<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps user entitlement.

.DESCRIPTION
Looks up a user by principal name (email / UPN) and reports whether they exist in the organization and
whether their assigned access level (account license type) matches the desired state.

.PARAMETER UserPrincipalName
The user's principal name (email / UPN).

.PARAMETER AccountLicenseType
The desired account license type.

.PARAMETER LookupResult
A hashtable to store the lookup result.

.PARAMETER Ensure
Specifies the desired state.

.OUTPUTS
System.Collections.Hashtable
#>
function Get-AzDoUserEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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
        [Ensure]$Ensure
    )

    Write-Verbose "[Get-AzDoUserEntitlement] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $result = @{
        Ensure             = [Ensure]::Absent
        UserPrincipalName  = $UserPrincipalName
        AccountLicenseType = $AccountLicenseType
        propertiesChanged  = @()
        status             = $null
    }

    $entitlement = Get-DevOpsUserEntitlement -Organization $OrganizationName -PrincipalName $UserPrincipalName

    if ($null -eq $entitlement)
    {
        Write-Verbose "[Get-AzDoUserEntitlement] User not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    # Carry the resolved id so callers can reference it without a second lookup.
    $result.userId = $entitlement.id

    $currentLicense = $entitlement.accessLevel.accountLicenseType
    if ($AccountLicenseType -and ($AccountLicenseType -ne $currentLicense))
    {
        Write-Verbose "[Get-AzDoUserEntitlement] Access level changed. Current: '$currentLicense', Desired: '$AccountLicenseType'."
        $result.status = [DSCGetSummaryState]::Changed
        $result.propertiesChanged += 'AccountLicenseType'
    }

    if ($result.propertiesChanged.Count -eq 0)
    {
        $result.status = [DSCGetSummaryState]::Unchanged
        Write-Verbose "[Get-AzDoUserEntitlement] User entitlement is in the desired state."
    }

    return $result
}
