<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps classic Release folder.

.DESCRIPTION
Looks the folder up live and compares its description against the desired state.

Paths are normalized before comparison, so the several ways a folder path can be written -
backslashes or forward slashes, with or without a leading or trailing separator - are treated as
one desired state rather than as drift.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the Release folder.

.PARAMETER Description
The folder description.

.PARAMETER AllowRecursiveDelete
Permit deletion of a folder that still contains release definitions or sub-folders.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoReleaseFolder -ProjectName 'Contoso' -Path '\Platform'
#>
Function Get-AzDoReleaseFolder
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
        [AllowEmptyString()]
        [System.String]$Description,

        [Parameter()]
        [System.Boolean]$AllowRecursiveDelete,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoReleaseFolder] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
        path              = (Format-AzDoPipelineFolderPath -Path $Path)
    }

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = $result.path

    if ($normalizedPath -eq '\')
    {
        Write-Error "[Get-AzDoReleaseFolder] The project release root cannot be managed as a folder. Supply a path beneath it."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'RootPathNotManageable'
        return $result
    }

    # The listing is scoped to the folder's own path; the API returns the folder itself when it
    # exists, and nothing when it does not.
    $folders = List-DevOpsReleaseFolders -Organization $organization -ProjectName $ProjectName -Path $normalizedPath
    $folder  = $folders | Where-Object { (Format-AzDoPipelineFolderPath -Path $_.path) -eq $normalizedPath } | Select-Object -First 1

    if ($null -eq $folder)
    {
        Write-Verbose "[Get-AzDoReleaseFolder] Release folder '$normalizedPath' does not exist in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $folder
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    # Only compare a description the configuration actually states - an unspecified Description is
    # not an instruction to clear one somebody set in the UI.
    if ($PSBoundParameters.ContainsKey('Description') -and (-not [String]::IsNullOrWhiteSpace($Description)))
    {
        if ("$($folder.description)" -ne "$Description")
        {
            Write-Verbose "[Get-AzDoReleaseFolder] Description differs for release folder '$normalizedPath'."
            $propertiesChanged += 'Description'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoReleaseFolder] Release folder '$normalizedPath' status: $($result.status)."

    return $result
}
