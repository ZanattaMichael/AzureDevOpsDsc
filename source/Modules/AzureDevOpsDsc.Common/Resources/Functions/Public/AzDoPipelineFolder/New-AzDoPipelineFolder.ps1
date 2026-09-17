<#
.SYNOPSIS
Creates an Azure DevOps pipeline folder.

.DESCRIPTION
Creates the folder at the configured path. The Build folders API creates missing ancestors
implicitly, so a nested folder does not require each level above it to be declared first - unlike
the work item query tree.

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
New-AzDoPipelineFolder -ProjectName 'Contoso' -Path '\Platform' -Description 'Platform pipelines'
#>
Function New-AzDoPipelineFolder
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

    Write-Verbose "[New-AzDoPipelineFolder] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    if ($normalizedPath -eq '\')
    {
        Write-Error "[New-AzDoPipelineFolder] The project build root already exists and cannot be created."
        return
    }

    Write-Verbose "[New-AzDoPipelineFolder] Creating pipeline folder '$normalizedPath'."

    $created = New-DevOpsPipelineFolder -Organization $organization -ProjectName $ProjectName `
        -Path $normalizedPath -Description $Description

    if ($null -eq $created)
    {
        Write-Error "[New-AzDoPipelineFolder] Failed to create pipeline folder '$normalizedPath' in project '$ProjectName'."
        return
    }

    return $created
}
