<#
.SYNOPSIS
Removes an Azure DevOps pipeline folder.

.DESCRIPTION
Deletes the folder. Deleting a pipeline folder deletes every pipeline definition beneath it, so a
folder that still has contents is left alone unless AllowRecursiveDelete is set. Without that
guard, narrowing a configuration to remove one folder would take an arbitrary number of pipelines
with it.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The full path of the pipeline folder.

.PARAMETER Description
The folder description.

.PARAMETER AllowRecursiveDelete
Permit deletion of a folder that still contains pipelines or sub-folders.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoPipelineFolder -ProjectName 'Contoso' -Path '\Platform' -AllowRecursiveDelete $true
#>
Function Remove-AzDoPipelineFolder
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

    Write-Verbose "[Remove-AzDoPipelineFolder] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    if ($normalizedPath -eq '\')
    {
        Write-Error "[Remove-AzDoPipelineFolder] The project build root cannot be removed."
        return
    }

    $folders = List-DevOpsPipelineFolders -Organization $organization -ProjectName $ProjectName -Path $normalizedPath
    $folder  = $folders | Where-Object { (Format-AzDoPipelineFolderPath -Path $_.path) -eq $normalizedPath } | Select-Object -First 1

    if ($null -eq $folder)
    {
        Write-Verbose "[Remove-AzDoPipelineFolder] Pipeline folder '$normalizedPath' does not exist. Nothing to remove."
        return
    }

    if (-not $AllowRecursiveDelete)
    {
        # Anything listed beneath this path other than the folder itself means the delete would
        # take definitions or sub-folders with it.
        $children = @($folders | Where-Object { (Format-AzDoPipelineFolderPath -Path $_.path) -ne $normalizedPath })

        try
        {
            $definitions = Get-DevOpsPipelineDefinitionsInFolder -Organization $organization -ProjectName $ProjectName -Path $normalizedPath
        }
        catch
        {
            # Emptiness could not be established, so the guard cannot be satisfied. Refusing is
            # the safe outcome: the alternative is deleting pipelines on the strength of a failed
            # lookup.
            Write-Error "[Remove-AzDoPipelineFolder] Could not determine whether pipeline folder '$normalizedPath' is empty, so it has not been removed. Error: $_"
            return
        }

        if ($children.Count -gt 0 -or (@($definitions).Count -gt 0))
        {
            Write-Error "[Remove-AzDoPipelineFolder] Pipeline folder '$normalizedPath' in project '$ProjectName' is not empty. Deleting it would delete every pipeline and sub-folder beneath it. Set AllowRecursiveDelete = \$true to permit this."
            return
        }
    }
    else
    {
        Write-Warning "[Remove-AzDoPipelineFolder] Recursively deleting pipeline folder '$normalizedPath' and everything beneath it."
    }

    Write-Verbose "[Remove-AzDoPipelineFolder] Removing pipeline folder '$normalizedPath'."

    return (Remove-DevOpsPipelineFolder -Organization $organization -ProjectName $ProjectName -Path $normalizedPath)
}
