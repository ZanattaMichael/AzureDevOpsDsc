<#
.SYNOPSIS
Removes an Azure DevOps shared work item query.

.DESCRIPTION
Deletes the query. The query is moved to the project's query recycle bin rather than being
destroyed outright, which is why re-creating the same path later can return a name conflict -
New-AzDoWorkItemQuery handles that by restoring the deleted item.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the query to remove.

.PARAMETER Wiql
Passed through from the resource; not used when removing.

.PARAMETER QueryType
Passed through from the resource; not used when removing.

.PARAMETER Columns
Passed through from the resource; not used when removing.

.PARAMETER SortColumns
Passed through from the resource; not used when removing.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoWorkItemQuery -ProjectName 'Contoso' -Path 'Shared Queries/Active Bugs'
#>
Function Remove-AzDoWorkItemQuery
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

    Write-Verbose "[Remove-AzDoWorkItemQuery] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoQueryPath -Path $Path

    $query = $LookupResult.liveCache

    if ($null -eq $query)
    {
        $query = Get-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath
    }

    if ($null -eq $query)
    {
        Write-Verbose "[Remove-AzDoWorkItemQuery] Query '$normalizedPath' does not exist. Nothing to remove."
        return
    }

    # Refuse to delete a folder through the query resource: the folder delete is recursive and
    # would take every query beneath it. AzDoQueryFolder owns that decision.
    if ($query.isFolder)
    {
        Write-Error "[Remove-AzDoWorkItemQuery] '$normalizedPath' in project '$ProjectName' is a folder, not a query. Use AzDoQueryFolder to remove it."
        return
    }

    Write-Verbose "[Remove-AzDoWorkItemQuery] Removing query '$normalizedPath'."

    return (Remove-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath)
}
