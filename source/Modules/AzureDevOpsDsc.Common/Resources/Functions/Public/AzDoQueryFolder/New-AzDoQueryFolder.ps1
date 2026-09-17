<#
.SYNOPSIS
Creates an Azure DevOps work item query folder.

.DESCRIPTION
Creates the folder beneath its parent. The parent must already exist - this function does not
create ancestry, because doing so would let two folder resources in the same configuration
race to create a shared parent. Declare each level as its own AzDoQueryFolder resource and
chain them with DependsOn.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the folder to create, including the root.

.PARAMETER AllowRecursiveDelete
Passed through from the resource; not used when creating.

.PARAMETER LookupResult
The lookup result from Get, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoQueryFolder -ProjectName 'Contoso' -Path 'Shared Queries/Platform'
#>
Function New-AzDoQueryFolder
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

    Write-Verbose "[New-AzDoQueryFolder] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoQueryPath -Path $Path
    $segments       = @($normalizedPath -split '/' | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

    if ($segments.Count -lt 2)
    {
        Write-Error "[New-AzDoQueryFolder] '$normalizedPath' is not a valid folder path. A folder must live beneath a root such as 'Shared Queries'."
        return
    }

    $folderName = $segments[-1]
    $parentPath = ($segments[0..($segments.Count - 2)]) -join '/'

    # Fail with the name of the missing parent rather than letting the API return a generic error.
    $parent = Get-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $parentPath

    if ($null -eq $parent)
    {
        Write-Error "[New-AzDoQueryFolder] Parent folder '$parentPath' does not exist in project '$ProjectName'. Create it first (AzDoQueryFolder with DependsOn)."
        return
    }

    if (-not $parent.isFolder)
    {
        Write-Error "[New-AzDoQueryFolder] Parent path '$parentPath' in project '$ProjectName' is a query, not a folder."
        return
    }

    Write-Verbose "[New-AzDoQueryFolder] Creating folder '$folderName' under '$parentPath'."

    $created = New-DevOpsQuery -Organization $organization -ProjectName $ProjectName `
        -ParentPath $parentPath -Name $folderName -IsFolder

    if ($null -ne $created)
    {
        return $created
    }

    # Deleted queries and folders go to a recycle bin rather than disappearing, so re-creating a
    # path that was deleted earlier comes back as a name conflict. Restoring the existing item is
    # the outcome the configuration asked for.
    Write-Verbose "[New-AzDoQueryFolder] Create failed. Checking whether '$normalizedPath' exists in the query recycle bin."

    $deleted = Get-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath -IncludeDeleted

    if ($null -ne $deleted -and $deleted.isDeleted)
    {
        Write-Verbose "[New-AzDoQueryFolder] Restoring '$normalizedPath' from the query recycle bin."
        return (Update-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath -UndeleteDescendants)
    }

    Write-Error "[New-AzDoQueryFolder] Failed to create query folder '$normalizedPath' in project '$ProjectName'."
    return
}
