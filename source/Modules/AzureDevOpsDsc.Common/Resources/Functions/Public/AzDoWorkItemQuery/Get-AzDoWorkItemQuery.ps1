<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps shared work item query.

.DESCRIPTION
Looks the query up live (with $expand=all, which is what populates wiql, columns and
sortColumns) and compares it against the desired state.

Two comparison rules are worth knowing about:

WIQL is compared in normalized form. The Queries API does not return the WIQL it was given -
it re-indents, re-wraps and re-cases it - so comparing the raw strings would report drift on
every Test(), forever, even when nothing had changed. See ConvertTo-NormalizedWiql.

Properties the configuration does not specify are not compared. A configuration that sets
only Wiql is stating an intent about the WIQL, not an intent that the query should have no
columns; treating an unspecified property as "must be empty" would strip display columns from
every query the configuration touched.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the query, including the root and any folders.

.PARAMETER Wiql
The desired WIQL statement.

.PARAMETER QueryType
The desired query type: 'flat', 'tree' or 'oneHop'.

.PARAMETER Columns
The desired display columns, as field reference names.

.PARAMETER SortColumns
The desired sort order: @{ Field = 'System.Id'; Descending = $false }.

.PARAMETER LookupResult
The lookup result from a previous call, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoWorkItemQuery -ProjectName 'Contoso' -Path 'Shared Queries/Active Bugs' -Wiql $wiql
#>
Function Get-AzDoWorkItemQuery
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoWorkItemQuery] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
        path              = (Format-AzDoQueryPath -Path $Path)
    }

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = $result.path

    if ([String]::IsNullOrWhiteSpace($normalizedPath))
    {
        Write-Error "[Get-AzDoWorkItemQuery] A query path must be supplied."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EmptyPath'
        return $result
    }

    $query = Get-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath -Expand 'all'

    if ($null -eq $query)
    {
        Write-Verbose "[Get-AzDoWorkItemQuery] Query '$normalizedPath' does not exist."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    # A folder occupying the query's path is a conflict the resource must not resolve on its
    # own - removing it would delete every query beneath it.
    if ($query.isFolder)
    {
        Write-Error "[Get-AzDoWorkItemQuery] The path '$normalizedPath' exists in project '$ProjectName' but is a folder, not a query. Refusing to manage it as a query."
        $result.status    = [DSCGetSummaryState]::Error
        $result.reason    = 'PathIsAFolder'
        $result.liveCache = $query
        return $result
    }

    $result.liveCache = $query
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    # WIQL: compare normalized forms, but never store the normalized form back.
    if ($PSBoundParameters.ContainsKey('Wiql') -and (-not [String]::IsNullOrWhiteSpace($Wiql)))
    {
        $desiredWiql = ConvertTo-NormalizedWiql -Wiql $Wiql
        $currentWiql = ConvertTo-NormalizedWiql -Wiql $query.wiql

        if ($desiredWiql -ne $currentWiql)
        {
            Write-Verbose "[Get-AzDoWorkItemQuery] WIQL differs for '$normalizedPath'."
            $propertiesChanged += 'Wiql'
        }
    }

    if ($PSBoundParameters.ContainsKey('QueryType') -and (-not [String]::IsNullOrWhiteSpace($QueryType)))
    {
        if ($QueryType -ne [String]$query.queryType)
        {
            Write-Verbose "[Get-AzDoWorkItemQuery] QueryType differs for '$normalizedPath' (desired '$QueryType', current '$($query.queryType)')."
            $propertiesChanged += 'QueryType'
        }
    }

    # Column order is meaningful - it is the order they appear in the results grid - so these
    # are compared as ordered sequences rather than as sets.
    if ($PSBoundParameters.ContainsKey('Columns') -and $Columns.Count -gt 0)
    {
        $currentColumns = @($query.columns | ForEach-Object { $_.referenceName })

        if (($Columns -join '|') -ne ($currentColumns -join '|'))
        {
            Write-Verbose "[Get-AzDoWorkItemQuery] Columns differ for '$normalizedPath'."
            $propertiesChanged += 'Columns'
        }
    }

    if ($PSBoundParameters.ContainsKey('SortColumns') -and $SortColumns.Count -gt 0)
    {
        $desiredSort = @($SortColumns | ForEach-Object { '{0}:{1}' -f $_.Field, ([bool]$_.Descending) })
        $currentSort = @($query.sortColumns | ForEach-Object { '{0}:{1}' -f $_.field.referenceName, ([bool]$_.descending) })

        if (($desiredSort -join '|') -ne ($currentSort -join '|'))
        {
            Write-Verbose "[Get-AzDoWorkItemQuery] SortColumns differ for '$normalizedPath'."
            $propertiesChanged += 'SortColumns'
        }
    }

    $result.propertiesChanged = $propertiesChanged

    if ($propertiesChanged.Count -gt 0)
    {
        $result.status = [DSCGetSummaryState]::Changed
    }
    else
    {
        $result.status = [DSCGetSummaryState]::Unchanged
    }

    Write-Verbose "[Get-AzDoWorkItemQuery] Query '$normalizedPath' status: $($result.status)."

    return $result
}
