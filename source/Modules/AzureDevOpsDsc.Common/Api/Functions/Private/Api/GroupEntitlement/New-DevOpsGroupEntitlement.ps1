<#
.SYNOPSIS
Creates an Azure DevOps group entitlement (group licensing rule).

.DESCRIPTION
Creates a licensing rule that assigns an access level to every member of a group.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER GroupDisplayName
The display name or principal name of the group.

.PARAMETER AccountLicenseType
The access level to assign, for example 'express', 'stakeholder' or 'advanced'.

.PARAMETER GroupOrigin
The identity origin: 'aad' for a Microsoft Entra group, 'vsts' for an Azure DevOps group.

.PARAMETER GroupOriginId
The origin id (Entra object id) when the group is an Entra group.

.EXAMPLE
New-DevOpsGroupEntitlement -Organization 'myorg' -GroupDisplayName 'Contoso Developers' -AccountLicenseType 'express'
#>
function New-DevOpsGroupEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$GroupDisplayName,

        [Parameter(Mandatory = $true)]
        [string]$AccountLicenseType,

        [Parameter()]
        [string]$GroupOrigin = 'aad',

        [Parameter()]
        [string]$GroupOriginId,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/groupentitlements?api-version={1}' -f $Organization, $ApiVersion

    $group = @{
        displayName   = $GroupDisplayName
        principalName = $GroupDisplayName
        origin        = $GroupOrigin
        subjectKind   = 'group'
    }

    if (-not [String]::IsNullOrWhiteSpace($GroupOriginId)) { $group.originId = $GroupOriginId }

    $body = @{
        group       = $group
        licenseRule = @{
            licensingSource    = 'account'
            accountLicenseType = $AccountLicenseType
        }
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 6))
    }
    catch
    {
        Write-Error "[New-DevOpsGroupEntitlement] Failed to create the group entitlement for '$GroupDisplayName'. Error: $_"
        return $null
    }
}
