<#
.SYNOPSIS
Creates an Azure DevOps group licensing rule.

.DESCRIPTION
Creates the rule that assigns an access level to every member of the group.

.PARAMETER GroupDisplayName
The display name or principal name of the group.

.PARAMETER AccountLicenseType
The access level the rule assigns.

.PARAMETER GroupOrigin
The identity origin: 'aad' or 'vsts'.

.PARAMETER GroupOriginId
The Entra object id of the group.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoGroupEntitlement -GroupDisplayName 'Contoso Developers' -AccountLicenseType 'express'
#>
Function New-AzDoGroupEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('GroupName')]
        [System.String]$GroupDisplayName,

        [Parameter()]
        [System.String]$AccountLicenseType,

        [Parameter()]
        [System.String]$GroupOrigin,

        [Parameter()]
        [System.String]$GroupOriginId,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoGroupEntitlement] Started."

    if ([String]::IsNullOrWhiteSpace($AccountLicenseType))
    {
        Write-Error "[New-AzDoGroupEntitlement] AccountLicenseType is required to create a licensing rule for group '$GroupDisplayName'."
        return
    }

    $OrganizationName = Get-AzDoOrganizationName

    $params = @{
        Organization       = $OrganizationName
        GroupDisplayName   = $GroupDisplayName
        AccountLicenseType = $AccountLicenseType
    }

    if (-not [String]::IsNullOrWhiteSpace($GroupOrigin))   { $params.GroupOrigin = $GroupOrigin }
    if (-not [String]::IsNullOrWhiteSpace($GroupOriginId)) { $params.GroupOriginId = $GroupOriginId }

    $created = New-DevOpsGroupEntitlement @params

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoGroupEntitlement] Failed to create the licensing rule for group '$GroupDisplayName'."
        return
    }

    return $created
}
