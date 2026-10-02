<#
.SYNOPSIS
Updates a classic Release folder's description.

.DESCRIPTION
PATCHes an update to a Release folder identified by its current path.

This endpoint is also how a folder is renamed or moved - supplying a different path in the body
moves the folder and every definition beneath it. The DSC resource treats the path as its key and
does not use that behaviour, because a mistyped path would silently relocate a whole tree.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The current path of the folder.

.PARAMETER Description
The description the folder should have.

.EXAMPLE
Update-DevOpsReleaseFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform' -Description 'Platform releases'
#>
Function Update-DevOpsReleaseFolder
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
        [AllowEmptyString()]
        [System.String]$Description,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    $uri = 'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/folders?path={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    $body = @{
        path        = $normalizedPath
        description = $Description
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[Update-DevOpsReleaseFolder] Failed to update release folder '$normalizedPath' in project '$ProjectName'. Error: $_"
    }
}
