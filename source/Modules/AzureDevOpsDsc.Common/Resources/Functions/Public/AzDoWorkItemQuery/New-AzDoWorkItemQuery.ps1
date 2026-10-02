<#
.SYNOPSIS
Creates an Azure DevOps shared work item query.

.DESCRIPTION
Creates the query beneath its parent folder. The parent folder must already exist - declare it
with AzDoQueryFolder and chain the query to it with DependsOn.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the query to create, including the root and any folders.

.PARAMETER Wiql
The WIQL statement backing the query.

.PARAMETER QueryType
'flat', 'tree' or 'oneHop'.

.PARAMETER Columns
Display columns, as field reference names.

.PARAMETER SortColumns
Sort order: @{ Field = 'System.Id'; Descending = $false }.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoWorkItemQuery -ProjectName 'Contoso' -Path 'Shared Queries/Active Bugs' -Wiql $wiql
#>
Function New-AzDoWorkItemQuery
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

    Write-Verbose "[New-AzDoWorkItemQuery] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoQueryPath -Path $Path
    $segments       = @($normalizedPath -split '/' | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

    if ($segments.Count -lt 2)
    {
        Write-Error "[New-AzDoWorkItemQuery] '$normalizedPath' is not a valid query path. A query must live beneath a root such as 'Shared Queries'."
        return
    }

    if ([String]::IsNullOrWhiteSpace($Wiql))
    {
        Write-Error "[New-AzDoWorkItemQuery] A WIQL statement is required to create query '$normalizedPath'."
        return
    }

    $queryName  = $segments[-1]
    $parentPath = ($segments[0..($segments.Count - 2)]) -join '/'

    $parent = Get-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $parentPath

    if ($null -eq $parent)
    {
        Write-Error "[New-AzDoWorkItemQuery] Parent folder '$parentPath' does not exist in project '$ProjectName'. Create it first (AzDoQueryFolder with DependsOn)."
        return
    }

    if (-not $parent.isFolder)
    {
        Write-Error "[New-AzDoWorkItemQuery] Parent path '$parentPath' in project '$ProjectName' is a query, not a folder."
        return
    }

    Write-Verbose "[New-AzDoWorkItemQuery] Creating query '$queryName' under '$parentPath'."

    $params = @{
        Organization = $organization
        ProjectName  = $ProjectName
        ParentPath   = $parentPath
        Name         = $queryName
        Wiql         = $Wiql
    }

    if (-not [String]::IsNullOrWhiteSpace($QueryType)) { $params.QueryType = $QueryType }
    if ($Columns.Count -gt 0)                          { $params.Columns = $Columns }
    if ($SortColumns.Count -gt 0)                      { $params.SortColumns = $SortColumns }

    $created = New-DevOpsQuery @params

    if ($null -ne $created)
    {
        return $created
    }

    # Deleted queries go to a recycle bin, so re-creating a previously deleted path comes back
    # as a name conflict rather than succeeding.
    Write-Verbose "[New-AzDoWorkItemQuery] Create failed. Checking whether '$normalizedPath' exists in the query recycle bin."

    $deleted = Get-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath -IncludeDeleted

    if ($null -ne $deleted -and $deleted.isDeleted)
    {
        Write-Verbose "[New-AzDoWorkItemQuery] Restoring '$normalizedPath' from the query recycle bin."

        $restored = Update-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath -UndeleteDescendants

        if ($null -ne $restored)
        {
            # The restored query carries whatever WIQL it had when it was deleted, which is not
            # necessarily the WIQL this configuration asks for.
            return (Set-AzDoWorkItemQuery @PSBoundParameters)
        }
    }

    Write-Error "[New-AzDoWorkItemQuery] Failed to create query '$normalizedPath' in project '$ProjectName'."
    return
}
