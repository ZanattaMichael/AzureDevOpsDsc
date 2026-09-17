<#
.SYNOPSIS
Creates a work item query or query folder.

.DESCRIPTION
Creates a query or folder beneath an existing parent path via the Azure DevOps Queries API.
The parent folder must already exist; this function does not create ancestry.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER ParentPath
The path of the parent folder (for example 'Shared Queries/Platform').

.PARAMETER Name
The name of the query or folder to create.

.PARAMETER IsFolder
Create a folder rather than a query.

.PARAMETER Wiql
The WIQL statement. Required for queries, ignored for folders.

.PARAMETER QueryType
'flat', 'tree' or 'oneHop'. Ignored for folders.

.PARAMETER Columns
Field reference names to display as columns.

.PARAMETER SortColumns
Sort columns, as an array of hashtables: @{ Field = 'System.Id'; Descending = $false }.

.EXAMPLE
New-DevOpsQuery -Organization 'myorg' -ProjectName 'MyProject' -ParentPath 'Shared Queries' -Name 'Bugs' -Wiql $wiql
#>
Function New-DevOpsQuery
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
        [String]$ParentPath,

        [Parameter(Mandatory = $true)]
        [String]$Name,

        [Parameter()]
        [Switch]$IsFolder,

        [Parameter()]
        [String]$Wiql,

        [Parameter()]
        [String]$QueryType,

        [Parameter()]
        [String[]]$Columns,

        [Parameter()]
        [HashTable[]]$SortColumns,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedParent = Format-AzDoQueryPath -Path $ParentPath
    $encodedParent = ($normalizedParent -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '/'

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/queries/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $encodedParent, $ApiVersion

    $body = @{
        name     = $Name
        isFolder = [bool]$IsFolder.IsPresent
    }

    if (-not $IsFolder.IsPresent)
    {
        $body.wiql = $Wiql

        if (-not [String]::IsNullOrWhiteSpace($QueryType))
        {
            $body.queryType = $QueryType
        }

        if ($Columns.Count -gt 0)
        {
            $body.columns = @($Columns | ForEach-Object { @{ referenceName = $_ } })
        }

        if ($SortColumns.Count -gt 0)
        {
            $body.sortColumns = @($SortColumns | ForEach-Object {
                @{
                    field      = @{ referenceName = $_.Field }
                    descending = [bool]$_.Descending
                }
            })
        }
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[New-DevOpsQuery] Failed to create '$Name' under '$normalizedParent' in project '$ProjectName'. Error: $_"
        return $null
    }
}
