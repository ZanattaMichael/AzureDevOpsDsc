<#
.SYNOPSIS
Lists the Release definitions stored directly in a Release folder.

.DESCRIPTION
Used to decide whether deleting a Release folder would take definitions with it. The Release
folders listing reports sub-folders but not the definitions inside them, so emptiness has to be
checked against the definitions endpoint as well.

Returns an empty array rather than $null when the folder holds no definitions, so callers can
count the result without guarding for null.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The Release folder path to inspect.

.EXAMPLE
Get-DevOpsReleaseDefinitionsInFolder -Organization 'myorg' -ProjectName 'MyProject' -Path '\Platform'
#>
Function Get-DevOpsReleaseDefinitionsInFolder
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

        [Parameter(Mandatory = $true)]
        [System.String]$Path,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoPipelineFolderPath -Path $Path

    $uri = 'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/definitions?path={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    try
    {
        return @((Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value)
    }
    catch
    {
        # Throw rather than returning an empty array. The caller uses this to decide whether a
        # folder is safe to delete, and an empty result means "safe" - so swallowing a transient
        # API error here would turn it into permission to delete the folder's contents.
        throw "[Get-DevOpsReleaseDefinitionsInFolder] Failed to list release definitions in '$normalizedPath' for project '$ProjectName'. Error: $_"
    }
}
