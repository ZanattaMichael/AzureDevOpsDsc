<#
.SYNOPSIS
Updates an Azure DevOps shared work item query.

.DESCRIPTION
Applies the desired WIQL, query type, columns and sort order to an existing query with PATCH.

Updating in place matters: recreating a query gives it a new id, and dashboard widgets,
delivery plans and ACL tokens all reference queries by id. A delete-and-recreate would leave
those pointing at nothing, without any error to explain why.

Only the properties the configuration specifies are sent, so a configuration that manages a
query's WIQL does not also silently reset columns somebody set in the UI.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the query.

.PARAMETER Wiql
The desired WIQL statement.

.PARAMETER QueryType
The desired query type.

.PARAMETER Columns
The desired display columns.

.PARAMETER SortColumns
The desired sort order.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoWorkItemQuery -ProjectName 'Contoso' -Path 'Shared Queries/Active Bugs' -Wiql $wiql
#>
Function Set-AzDoWorkItemQuery
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Alias('QueryPath')]
        [System.String]$Path,

        [Parameter()]
        [System.String]$Wiql,

        [Parameter()]
        [System.String]$QueryType,

        [Parameter()]
        [System.String[]]$Columns,

        [Parameter()]
        [HashTable[]]$SortColumns,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoWorkItemQuery] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoQueryPath -Path $Path

    if ($LookupResult.reason -eq 'PathIsAFolder')
    {
        Write-Error "[Set-AzDoWorkItemQuery] Cannot manage '$normalizedPath' in project '$ProjectName' as a query: a folder already exists at that path. Choose another path."
        return
    }

    $params = @{
        Organization = $organization
        ProjectName  = $ProjectName
        Path         = $normalizedPath
    }

    if (-not [String]::IsNullOrWhiteSpace($Wiql))      { $params.Wiql = $Wiql }
    if (-not [String]::IsNullOrWhiteSpace($QueryType)) { $params.QueryType = $QueryType }
    if ($Columns.Count -gt 0)                          { $params.Columns = $Columns }
    if ($SortColumns.Count -gt 0)                      { $params.SortColumns = $SortColumns }

    if ($params.Keys.Count -le 3)
    {
        Write-Verbose "[Set-AzDoWorkItemQuery] No updatable properties supplied for '$normalizedPath'. No action taken."
        return
    }

    Write-Verbose "[Set-AzDoWorkItemQuery] Updating query '$normalizedPath'."

    return (Update-DevOpsQuery @params)
}
