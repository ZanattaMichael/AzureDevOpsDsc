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
        [String]$ApiVersion = '7.1'
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
        throw "[List-DevOpsPipelineFolders] Failed to list pipeline folders for project '$ProjectName'. Error: $_"
    }
}
