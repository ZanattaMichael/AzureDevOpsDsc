<#
.SYNOPSIS
Removes an Azure DevOps classic Release folder.

.DESCRIPTION
Deletes the folder. Deleting a release folder deletes every release definition beneath it, so a
folder that still has contents is left alone unless AllowRecursiveDelete is set. Without that
guard, narrowing a configuration to remove one folder would take an arbitrary number of release
definitions with it.

Throws rather than writing a non-terminating error when the folder cannot safely be removed, so a
caller applying this resource via Invoke-DscResource sees the refusal rather than Set() reporting
success while later Test() calls report drift with no visible reason.

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
Remove-AzDoReleaseFolder -ProjectName 'Contoso' -Path '\Platform' -AllowRecursiveDelete $true
#>
Function Remove-AzDoReleaseFolder
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

    Write-Verbose "[Remove-AzDoReleaseFolder] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    if ($normalizedPath -eq '\')
    {
        throw "[Remove-AzDoReleaseFolder] The project release root cannot be removed."
    }

    $folders = List-DevOpsReleaseFolders -Organization $organization -ProjectName $ProjectName -Path $normalizedPath
    $folder  = $folders | Where-Object { (Format-AzDoPipelineFolderPath -Path $_.path) -eq $normalizedPath } | Select-Object -First 1

    if ($null -eq $folder)
    {
        Write-Verbose "[Remove-AzDoReleaseFolder] Release folder '$normalizedPath' does not exist. Nothing to remove."
        return
    }

    if (-not $AllowRecursiveDelete)
    {
        # Anything listed beneath this path other than the folder itself means the delete would
        # take definitions or sub-folders with it.
        $children = @($folders | Where-Object { (Format-AzDoPipelineFolderPath -Path $_.path) -ne $normalizedPath })

        try
        {
            $definitions = Get-DevOpsReleaseDefinitionsInFolder -Organization $organization -ProjectName $ProjectName -Path $normalizedPath
        }
        catch
        {
            # Emptiness could not be established, so the guard cannot be satisfied. Refusing is
            # the safe outcome: the alternative is deleting release definitions on the strength
            # of a failed lookup.
            throw "[Remove-AzDoReleaseFolder] Could not determine whether release folder '$normalizedPath' is empty, so it has not been removed. Error: $_"
        }

        if ($children.Count -gt 0 -or (@($definitions).Count -gt 0))
        {
            throw "[Remove-AzDoReleaseFolder] Release folder '$normalizedPath' in project '$ProjectName' is not empty. Deleting it would delete every release definition and sub-folder beneath it. Set AllowRecursiveDelete = `$true to permit this."
        }
    }
    else
    {
        Write-Warning "[Remove-AzDoReleaseFolder] Recursively deleting release folder '$normalizedPath' and everything beneath it."
    }

    Write-Verbose "[Remove-AzDoReleaseFolder] Removing release folder '$normalizedPath'."

    return (Remove-DevOpsReleaseFolder -Organization $organization -ProjectName $ProjectName -Path $normalizedPath)
}
