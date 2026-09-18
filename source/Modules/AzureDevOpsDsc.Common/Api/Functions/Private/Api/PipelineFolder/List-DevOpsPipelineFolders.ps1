<#
.SYNOPSIS
Lists the pipeline (build) folders in an Azure DevOps project.

.DESCRIPTION
Returns the build folder tree for a project. Unlike work item query folders, build folders are
first-class objects on their own endpoint rather than definitions carrying a flag, and they
carry a description.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
Restrict the listing to a path. Defaults to the root.

.EXAMPLE
List-DevOpsPipelineFolders -Organization 'myorg' -ProjectName 'MyProject'
#>
Function List-DevOpsPipelineFolders
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter()]
        [System.String]$Path = '\',

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
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        # Get-AzDoPipelineFolder calls this scoped to one folder's own path and reads an empty
        # result as "does not exist". Whether Azure DevOps answers that with an empty list or a
        # 404 is not something the old code could tell us - it swallowed every error into $null,
        # so both looked identical. Treat a not-found explicitly, the same way Get-DevOpsQuery
        # does, so the absent case is correct either way.
        if ($_ -match '404' -or $_ -match 'does not exist' -or $_ -match 'was not found')
        {
            Write-Verbose "[List-DevOpsPipelineFolders] No pipeline folder at '$normalizedPath' in project '$ProjectName'."
            return $null
        }

        # Anything else is a real failure. It must not read as "no folders": that would report an
        # existing folder as absent and invite a duplicate create.
        throw "[List-DevOpsPipelineFolders] Failed to list pipeline folders for project '$ProjectName'. Error: $_"
    }
}
