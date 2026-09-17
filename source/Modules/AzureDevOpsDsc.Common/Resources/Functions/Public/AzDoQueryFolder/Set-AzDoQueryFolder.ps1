<#
.SYNOPSIS
Updates an Azure DevOps work item query folder.

.DESCRIPTION
A query folder has no mutable state of its own. Its only identifying property is its path,
which is the resource Key - changing it describes a different folder, not a change to this
one. Set is therefore a deliberate no-op for the ordinary case.

It is still reached when Get reported an error state, most importantly when a query already
occupies the folder's path. That case is reported here rather than being silently resolved,
because the only way to resolve it would be to delete the user's query.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the folder.

.PARAMETER AllowRecursiveDelete
Passed through from the resource; not used when setting.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoQueryFolder -ProjectName 'Contoso' -Path 'Shared Queries/Platform'
#>
Function Set-AzDoQueryFolder
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [Alias('FolderPath')]
        [System.String]$Path,

        [Parameter()]
        [System.Boolean]$AllowRecursiveDelete,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    $normalizedPath = Format-AzDoQueryPath -Path $Path

    if ($LookupResult.reason -eq 'PathIsNotAFolder')
    {
        Write-Error "[Set-AzDoQueryFolder] Cannot manage '$normalizedPath' in project '$ProjectName' as a folder: a query already exists at that path. Remove or move the query, or choose another path."
        return
    }

    Write-Verbose "[Set-AzDoQueryFolder] Query folder '$normalizedPath' has no updatable properties. No action taken."
}
