<#
.SYNOPSIS
Lists the classic Release folders in an Azure DevOps project.

.DESCRIPTION
Returns the release folder tree for a project. Classic Release Management lives on the
'vsrm.dev.azure.com' host rather than 'dev.azure.com' - this host is confined to the Release
private API helpers, the same way the Build folder helpers hard-code 'dev.azure.com'.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
Restrict the listing to a path. Defaults to the root.

.EXAMPLE
List-DevOpsReleaseFolders -Organization 'myorg' -ProjectName 'MyProject'
#>
Function List-DevOpsReleaseFolders
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

    $uri = 'https://vsrm.dev.azure.com/{0}/{1}/_apis/release/folders?path={2}&api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), [System.Uri]::EscapeDataString($normalizedPath), $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        # As with pipeline folders: an explicit not-found must not collapse into the same $null
        # a real failure would return, or a transient error reads as "the folder does not exist"
        # and invites Get to hand back NotFound and New to create a duplicate.
        if ($_ -match '404' -or $_ -match 'does not exist' -or $_ -match 'was not found')
        {
            Write-Verbose "[List-DevOpsReleaseFolders] No release folder at '$normalizedPath' in project '$ProjectName'."
            return $null
        }

        throw "[List-DevOpsReleaseFolders] Failed to list release folders for project '$ProjectName'. Error: $_"
    }
}
