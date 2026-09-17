<#
.SYNOPSIS
Retrieves a single work item query or query folder by its path.

.DESCRIPTION
Calls the Azure DevOps Queries API for a single query or folder. Returns $null when the
path does not exist, rather than throwing, so callers can treat "not found" as a normal
Get() outcome.

Folders and queries share this endpoint; a folder is a query with 'isFolder' set to true.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The query path, relative to the project (for example 'Shared Queries/Platform/Release').

.PARAMETER Expand
The $expand value passed to the API. Defaults to 'all', which is required to return the
'wiql', 'columns' and 'sortColumns' values used for drift detection.

.PARAMETER Depth
The $depth value passed to the API. Only meaningful for folders.

.PARAMETER IncludeDeleted
Include items in the query recycle bin. Used when a create fails with a name conflict.

.EXAMPLE
Get-DevOpsQuery -Organization 'myorg' -ProjectName 'MyProject' -Path 'Shared Queries/Bugs'
#>
Function Get-DevOpsQuery
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [String]$Path,

        [Parameter()]
        [String]$Expand = 'all',

        [Parameter()]
        [Int]$Depth = 0,

        [Parameter()]
        [Switch]$IncludeDeleted,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoQueryPath -Path $Path

    # Each segment is escaped individually: the separators must survive as path separators,
    # but segment content ('Shared Queries') contains characters that must not.
    $encodedPath = ($normalizedPath -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '/'

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/queries/{2}?$expand={3}&$depth={4}&api-version={5}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $encodedPath, $Expand, $Depth, $ApiVersion

    if ($IncludeDeleted.IsPresent)
    {
        $uri += '&$includeDeleted=true'
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET')
    }
    catch
    {
        # A missing query/folder is an expected Get() outcome, not an error.
        if ($_ -match '404' -or $_ -match 'does not exist' -or $_ -match 'was not found')
        {
            Write-Verbose "[Get-DevOpsQuery] Query path '$normalizedPath' not found in project '$ProjectName'."
            return $null
        }

        Write-Error "[Get-DevOpsQuery] Failed to retrieve query '$normalizedPath' in project '$ProjectName'. Error: $_"
        return $null
    }
}
