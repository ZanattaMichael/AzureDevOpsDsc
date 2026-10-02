<#
.SYNOPSIS
Creates an Azure DevOps picklist.

.DESCRIPTION
Creates an organization-scoped picklist with the configured items.

.PARAMETER PicklistName
The name of the picklist.

.PARAMETER Items
The complete set of allowed values.

.PARAMETER PicklistType
'String' or 'Integer'.

.PARAMETER IsSuggested
Whether the list is a suggestion rather than a closed set.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoPicklist -PicklistName 'Severity' -Items @('Low','High')
#>
Function New-AzDoPicklist
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$PicklistName,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]$Items,

        [Parameter()]
        [System.String]$PicklistType = 'String',

        [Parameter()]
        [System.Boolean]$IsSuggested,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[New-AzDoPicklist] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $params = @{
        Organization = $OrganizationName
        PicklistName = $PicklistName
        Items        = @($Items)
        IsSuggested  = [bool]$IsSuggested
    }

    if (-not [String]::IsNullOrWhiteSpace($PicklistType)) { $params.PicklistType = $PicklistType }

    $created = New-DevOpsPicklist @params

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoPicklist] Failed to create picklist '$PicklistName'."
        return
    }

    return $created
}
