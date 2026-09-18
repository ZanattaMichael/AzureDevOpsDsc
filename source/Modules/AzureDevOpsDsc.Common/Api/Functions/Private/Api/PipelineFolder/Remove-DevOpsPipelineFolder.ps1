<#
.SYNOPSIS
Deletes a pipeline (build) folder.

.DESCRIPTION
Deletes a build folder by path. Deleting a folder deletes everything beneath it, including the
pipeline definitions it contains, so callers are expected to have confirmed that is intended.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The path of the folder to delete.

.EXAMPLE
Remove-DevOpsPipelineFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform'
#>
Function Remove-DevOpsPipelineFolder
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
        # The build/folders endpoint is preview-only. With a plain '7.1' Azure DevOps answers:
        #   "The requested version \"7.1\" of the resource is under preview. The -preview flag
        #    must be supplied in the api-version for such requests. For example: \"7.1-preview\""
        # That failure was invisible until the API-layer catches stopped swallowing it: the list
        # call returned $null, which Get read as "the folder does not exist".
        [String]$ApiVersion = '7.1-preview'
    )

    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/build/folders?path={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        throw "[Remove-DevOpsPipelineFolder] Failed to delete pipeline folder '$normalizedPath' in project '$ProjectName'. Error: $_"
    }
}
