<#
.SYNOPSIS
Removes an Azure DevOps work item query folder.

.DESCRIPTION
Deletes the folder. Deleting a folder in Azure DevOps deletes everything beneath it, so a
folder that still has children is left alone unless the resource sets AllowRecursiveDelete.
Without that guard, narrowing a configuration to remove one folder would take an arbitrary
number of other people's saved queries with it.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the folder to remove.

.PARAMETER AllowRecursiveDelete
Permit deletion of a folder that still contains queries or sub-folders.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoQueryFolder -ProjectName 'Contoso' -Path 'Shared Queries/Platform' -AllowRecursiveDelete $true
#>
Function Remove-AzDoQueryFolder
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

    Write-Verbose "[Remove-AzDoQueryFolder] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoQueryPath -Path $Path

    # Prefer the folder Get already retrieved (it was fetched with Depth 1 so that hasChildren
    # is populated); fall back to a fresh lookup when called outside the DSC pipeline.
    $folder = $LookupResult.liveCache

    if ($null -eq $folder)
    {
        $folder = Get-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath -Depth 1
    }

    if ($null -eq $folder)
    {
        Write-Verbose "[Remove-AzDoQueryFolder] Folder '$normalizedPath' does not exist. Nothing to remove."
        return
    }

    if (-not $folder.isFolder)
    {
        Write-Error "[Remove-AzDoQueryFolder] '$normalizedPath' in project '$ProjectName' is a query, not a folder. Refusing to remove it."
        return
    }

    $hasChildren = ($folder.hasChildren -eq $true) -or (@($folder.children).Where({ $null -ne $_ }).Count -gt 0)

    if ($hasChildren -and (-not $AllowRecursiveDelete))
    {
        Write-Error "[Remove-AzDoQueryFolder] Folder '$normalizedPath' in project '$ProjectName' is not empty. Deleting it would delete every query and sub-folder beneath it. Set AllowRecursiveDelete = `$true to permit this."
        return
    }

    if ($hasChildren)
    {
        Write-Warning "[Remove-AzDoQueryFolder] Recursively deleting folder '$normalizedPath' and all of its contents."
    }

    Write-Verbose "[Remove-AzDoQueryFolder] Removing folder '$normalizedPath'."

    return (Remove-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath)
}
