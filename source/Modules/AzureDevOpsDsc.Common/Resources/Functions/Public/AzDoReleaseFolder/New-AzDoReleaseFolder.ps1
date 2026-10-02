<#
.SYNOPSIS
Creates an Azure DevOps classic Release folder.

.DESCRIPTION
Creates the folder at the configured path. The Release folders API creates missing ancestors
implicitly, so a nested folder does not require each level above it to be declared first.

Throws when the folder cannot be created, including when classic Release Management creation is
disabled for the organization or project, so a caller applying this resource via
Invoke-DscResource sees the failure rather than Set() reporting success.

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
New-AzDoReleaseFolder -ProjectName 'Contoso' -Path '\Platform' -Description 'Platform releases'
#>
Function New-AzDoReleaseFolder
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

    Write-Verbose "[New-AzDoReleaseFolder] Started."

    $organization   = Get-AzDoOrganizationName
    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    if ($normalizedPath -eq '\')
    {
        throw "[New-AzDoReleaseFolder] The project release root already exists and cannot be created."
    }

    Write-Verbose "[New-AzDoReleaseFolder] Creating release folder '$normalizedPath'."

    $created = New-DevOpsReleaseFolder -Organization $organization -ProjectName $ProjectName `
        -Path $normalizedPath -Description $Description

    if ($null -eq $created)
    {
        throw "[New-AzDoReleaseFolder] Failed to create release folder '$normalizedPath' in project '$ProjectName'."
    }

    return $created
}
