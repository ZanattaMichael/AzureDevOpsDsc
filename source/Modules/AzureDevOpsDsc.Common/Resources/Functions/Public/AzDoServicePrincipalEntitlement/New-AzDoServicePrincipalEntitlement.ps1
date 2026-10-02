<#
.SYNOPSIS
Adds a service principal to the Azure DevOps organization.

.DESCRIPTION
Creates the entitlement that makes a service principal or managed identity a member of the
organization, with the configured access level.

.PARAMETER OriginId
The Microsoft Entra object id of the service principal.

.PARAMETER DisplayName
A display name recorded with the entitlement.

.PARAMETER AccountLicenseType
The access level to assign.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoServicePrincipalEntitlement -OriginId '00000000-0000-0000-0000-000000000000' -AccountLicenseType 'express'
#>
Function New-AzDoServicePrincipalEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('ObjectId')]
        [System.String]$OriginId,

        [Parameter()]
        [Alias('Name')]
        [System.String]$DisplayName,

        [Parameter()]
        [System.String]$AccountLicenseType,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoServicePrincipalEntitlement] Started."

    if ([String]::IsNullOrWhiteSpace($AccountLicenseType))
    {
        Write-Error "[New-AzDoServicePrincipalEntitlement] AccountLicenseType is required to add a service principal to the organization."
        return
    }

    $OrganizationName = Get-AzDoOrganizationName

    $created = New-DevOpsServicePrincipalEntitlement -Organization $OrganizationName `
        -OriginId $OriginId -DisplayName $DisplayName -AccountLicenseType $AccountLicenseType

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoServicePrincipalEntitlement] Failed to add the service principal to the organization."
        return
    }

    return $created
}
