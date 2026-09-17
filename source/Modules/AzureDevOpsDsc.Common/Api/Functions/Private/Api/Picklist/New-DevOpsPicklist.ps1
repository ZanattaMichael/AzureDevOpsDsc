<#
.SYNOPSIS
Creates a picklist in an Azure DevOps organization.

.DESCRIPTION
Creates an organization-scoped picklist with its items.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER PicklistName
The name of the picklist.

.PARAMETER Items
The list values.

.PARAMETER PicklistType
'String' or 'Integer'. Defaults to 'String'.

.PARAMETER IsSuggested
Whether the list is a suggestion rather than a closed set, which lets users enter their own value.

.EXAMPLE
New-DevOpsPicklist -Organization 'myorg' -PicklistName 'Severity' -Items @('Low','High')
#>
Function New-DevOpsPicklist
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$PicklistName,

        [Parameter()]
        [AllowEmptyCollection()]
        [String[]]$Items = @(),

        [Parameter()]
        [ValidateSet('String', 'Integer')]
        [String]$PicklistType = 'String',

        [Parameter()]
        [Boolean]$IsSuggested = $false,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/lists?api-version={1}' -f $Organization, $ApiVersion

    $body = @{
        name        = $PicklistName
        type        = $PicklistType
        items       = @($Items)
        isSuggested = $IsSuggested
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[New-DevOpsPicklist] Failed to create picklist '$PicklistName' in organization '$Organization'. Error: $_"
        return $null
    }
}
