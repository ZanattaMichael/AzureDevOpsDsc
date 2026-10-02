<#
.SYNOPSIS
Deletes a classic Release folder.

.DESCRIPTION
Deletes a Release folder by path. Deleting a folder deletes everything beneath it, including the
release definitions it contains, so callers are expected to have confirmed that is intended.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The path of the folder to delete.

.EXAMPLE
Remove-DevOpsReleaseFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform'
#>
Function Remove-DevOpsReleaseFolder
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$Path,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    $uri = 'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/folders?path={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        throw "[Remove-DevOpsReleaseFolder] Failed to delete release folder '$normalizedPath' in project '$ProjectName'. Error: $_"
    }
}
