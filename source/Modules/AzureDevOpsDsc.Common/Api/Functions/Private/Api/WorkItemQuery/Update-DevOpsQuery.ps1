<#
.SYNOPSIS
Updates an existing work item query or query folder.

.DESCRIPTION
PATCHes a query or folder via the Azure DevOps Queries API. Updating in place is preferred
over delete-and-recreate because recreating a query changes its id, which silently breaks
dashboard widgets, delivery plans and any ACL token that references it.

Only the parameters supplied by the caller are sent, so a caller can rename a query without
also having to restate its WIQL.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The current path of the query or folder to update.

.PARAMETER Name
A new name for the query or folder.

.PARAMETER Wiql
A new WIQL statement.

.PARAMETER QueryType
A new query type.

.PARAMETER Columns
New display columns, as field reference names.

.PARAMETER SortColumns
New sort columns: @{ Field = 'System.Id'; Descending = $false }.

.PARAMETER UndeleteDescendants
Restore the item (and its descendants) from the query recycle bin.

.EXAMPLE
Update-DevOpsQuery -Organization 'myorg' -ProjectName 'MyProject' -Path 'Shared Queries/Bugs' -Wiql $newWiql
#>
Function Update-DevOpsQuery
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
        [String]$Name,

        [Parameter()]
        [String]$Wiql,

        [Parameter()]
        [String]$QueryType,

        [Parameter()]
        [String[]]$Columns,

        [Parameter()]
        [HashTable[]]$SortColumns,

        [Parameter()]
        [Switch]$UndeleteDescendants,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoQueryPath -Path $Path
    $encodedPath = ($normalizedPath -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '/'

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/queries/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $encodedPath, $ApiVersion

    if ($UndeleteDescendants.IsPresent)
    {
        $uri += '&$undeleteDescendants=true'
    }

    $body = @{}

    if ($PSBoundParameters.ContainsKey('Name'))      { $body.name = $Name }
    if ($PSBoundParameters.ContainsKey('Wiql'))      { $body.wiql = $Wiql }
    if ($PSBoundParameters.ContainsKey('QueryType')) { $body.queryType = $QueryType }

    if ($UndeleteDescendants.IsPresent)
    {
        $body.isDeleted = $false
    }

    if ($PSBoundParameters.ContainsKey('Columns'))
    {
        $body.columns = @($Columns | ForEach-Object { @{ referenceName = $_ } })
    }

    if ($PSBoundParameters.ContainsKey('SortColumns'))
    {
        $body.sortColumns = @($SortColumns | ForEach-Object {
            @{
                field      = @{ referenceName = $_.Field }
                descending = [bool]$_.Descending
            }
        })
    }

    if ($body.Keys.Count -eq 0)
    {
        Write-Verbose "[Update-DevOpsQuery] No updatable values supplied for '$normalizedPath'. No action taken."
        return $null
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[Update-DevOpsQuery] Failed to update query '$normalizedPath' in project '$ProjectName'. Error: $_"
        return $null
    }
}
