<#
.SYNOPSIS
Deletes a work item query or query folder.

.DESCRIPTION
Deletes a query or folder via the Azure DevOps Queries API. Deleting a folder deletes its
entire subtree, so callers are expected to have confirmed the folder is empty (or that the
caller intended a recursive delete) before calling this function.

Deleted items go to the query recycle bin rather than disappearing outright, which is why
re-creating a deleted path can return a name conflict.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The path of the query or folder to delete.

.EXAMPLE
Remove-DevOpsQuery -Organization 'myorg' -ProjectName 'MyProject' -Path 'Shared Queries/Bugs'
#>
Function Remove-DevOpsQuery
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [String]$Path,

        [Parameter()]
        [String]$ApiVersion = '7.1'
    )

    $normalizedPath = Format-AzDoQueryPath -Path $Path
    $encodedPath = ($normalizedPath -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '/'

    $uri = 'https://dev.azure.com/{0}/{1}/_apis/wit/queries/{2}?api-version={3}' -f
        $Organization, [System.Uri]::EscapeDataString($ProjectName), $encodedPath, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsQuery] Failed to delete query '$normalizedPath' in project '$ProjectName'. Error: $_"
        return $null
    }
}
