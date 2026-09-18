<#
.SYNOPSIS
Updates a pipeline (build) folder's description.

.DESCRIPTION
POSTs an update to a build folder identified by its current path.

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
Update-DevOpsPipelineFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform' -Description 'Platform pipelines'
#>
Function Update-DevOpsPipelineFolder
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

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/build/folders?path={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    $body = @{
        path        = $normalizedPath
        description = $Description
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        throw "[Update-DevOpsPipelineFolder] Failed to update pipeline folder '$normalizedPath' in project '$ProjectName'. Error: $_"
    }
}
