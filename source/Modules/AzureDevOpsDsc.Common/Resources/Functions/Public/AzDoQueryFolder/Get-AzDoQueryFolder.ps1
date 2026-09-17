<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps work item query folder.

.DESCRIPTION
Looks the folder up live rather than through the module cache. Query paths are renamed and
moved by ordinary day-to-day use of the Azure DevOps UI, and a stale cache entry would make
Test() report a folder as present after somebody had deleted it. The lookup is a single
cheap API call, so there is nothing to gain by caching it.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the folder, including the root.

.PARAMETER AllowRecursiveDelete
Passed through from the resource; not used by the lookup.

.PARAMETER LookupResult
The lookup result from a previous call, supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoQueryFolder -ProjectName 'Contoso' -Path 'Shared Queries/Platform'
#>
Function Get-AzDoQueryFolder
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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

    Write-Verbose "[Get-AzDoQueryFolder] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
        path              = (Format-AzDoQueryPath -Path $Path)
    }

    $organization = Get-AzDoOrganizationName
    $normalizedPath = $result.path

    if ([String]::IsNullOrWhiteSpace($normalizedPath))
    {
        Write-Error "[Get-AzDoQueryFolder] A query folder path must be supplied."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'EmptyPath'
        return $result
    }

    # Depth 1 so the response carries 'hasChildren', which Remove() needs in order to refuse a
    # recursive delete that was not asked for.
    $folder = Get-DevOpsQuery -Organization $organization -ProjectName $ProjectName -Path $normalizedPath -Depth 1

    if ($null -eq $folder)
    {
        Write-Verbose "[Get-AzDoQueryFolder] Folder '$normalizedPath' does not exist."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    # A query already occupying the desired folder path is a conflict the resource must not
    # silently resolve - deleting it to make room would destroy someone's saved query.
    if (-not $folder.isFolder)
    {
        Write-Error "[Get-AzDoQueryFolder] The path '$normalizedPath' exists in project '$ProjectName' but is a query, not a folder. Refusing to manage it as a folder."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'PathIsNotAFolder'
        $result.liveCache = $folder
        return $result
    }

    Write-Verbose "[Get-AzDoQueryFolder] Folder '$normalizedPath' found."

    $result.liveCache = $folder
    $result.Ensure    = [Ensure]::Present
    $result.status    = [DSCGetSummaryState]::Unchanged

    return $result
}
