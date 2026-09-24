<#
.SYNOPSIS
Updates an Azure DevOps classic Release folder.

.DESCRIPTION
Applies the configured description to an existing folder.

The path is not updated here. The Release folders API treats a path change as a move, taking
every definition beneath the folder with it, and Path is this resource's key - so a different
path describes a different folder rather than a change to this one. That keeps a mistyped path
from silently relocating a tree.

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
Set-AzDoReleaseFolder -ProjectName 'Contoso' -Path '\Platform' -Description 'Platform releases'
#>
Function Set-AzDoReleaseFolder
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

    Write-Verbose "[Set-AzDoReleaseFolder] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    Write-Verbose "[Set-AzDoReleaseFolder] Updating release folder '$normalizedPath'."

    return (Update-DevOpsReleaseFolder -Organization $organization -ProjectName $ProjectName `
        -Path $normalizedPath -Description $Description)
}
