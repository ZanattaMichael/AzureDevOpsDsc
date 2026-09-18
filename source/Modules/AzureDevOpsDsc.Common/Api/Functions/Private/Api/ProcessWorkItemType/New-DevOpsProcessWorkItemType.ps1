<#
.SYNOPSIS
Creates a custom work item type on an inherited process.

.DESCRIPTION
Adds a new work item type to the process. Only inherited (custom) processes can be modified -
the system processes Agile, Scrum, Basic and CMMI are read-only, and the API rejects changes to
them.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER Name
The name of the work item type.

.PARAMETER Description
A description for the work item type.

.PARAMETER Color
The hex colour, without a leading '#', for example 'F6546A'.

.PARAMETER Icon
The icon name, for example 'icon_book'.

.PARAMETER IsDisabled
Whether the work item type is disabled.

.EXAMPLE
New-DevOpsProcessWorkItemType -Organization 'myorg' -ProcessId $id -Name 'Incident' -Color 'F6546A' -Icon 'icon_flame'
#>
Function New-DevOpsProcessWorkItemType
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProcessId,

        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter()]
        [AllowEmptyString()]
        [String]$Description,

        [Parameter()]
        [String]$Color = '009CCC',

        [Parameter()]
        [String]$Icon = 'icon_book',

        [Parameter()]
        [Boolean]$IsDisabled = $false,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypes?api-version={2}' -f
        $Organization, $ProcessId, $ApiVersion

    $body = @{
        name        = $Name
        description = $Description
        color       = $Color
        icon        = $Icon
        isDisabled  = $IsDisabled
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[New-DevOpsProcessWorkItemType] Failed to create work item type '$Name' on process '$ProcessId'. Error: $_"
        return $null
    }
}
