<#
.SYNOPSIS
Resolves a work item query path to its API object and its chain of ancestor ids.

.DESCRIPTION
Query ACL tokens address folders by GUID, not by name: the token for a folder is
'$/{projectId}/{rootFolderId}/{childFolderId}' and so on down the tree. A configuration,
however, is written in terms of readable paths. This helper bridges the two by walking the
path one segment at a time and collecting the id of each item along the way.

The walk stops at the first segment that does not exist. Callers can tell a complete
resolution from a partial one by comparing 'Resolved' against the requested segment count,
which is what lets a New() report exactly which parent folder is missing.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER Path
The query path to resolve, for example 'Shared Queries/Platform/Release'.

.OUTPUTS
A hashtable with:
  Path       - the normalized path that was requested
  Item       - the API object for the final segment, or $null if it does not exist
  IdChain    - the ids of each resolved segment, root first
  Resolved   - the number of segments successfully resolved
  Segments   - the requested path split into segments
  Exists     - $true when every segment resolved

.EXAMPLE
$resolved = Resolve-AzDoQueryPath -Organization 'myorg' -ProjectName 'MyProject' -Path 'Shared Queries/Platform'
#>
Function Resolve-AzDoQueryPath
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProjectName,

        # Empty is allowed so that the guard below can return a well-formed "nothing resolved"
        # result. Without it, binding fails first and the caller gets a parameter exception
        # instead of the documented output shape.
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$Path
    )

    $normalizedPath = Format-AzDoQueryPath -Path $Path
    $segments = @($normalizedPath -split '/' | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

    $result = @{
        Path     = $normalizedPath
        Item     = $null
        IdChain  = @()
        Resolved = 0
        Segments = $segments
        Exists   = $false
    }

    if ($segments.Count -eq 0)
    {
        Write-Verbose "[Resolve-AzDoQueryPath] Empty query path supplied."
        return $result
    }

    $walked = @()

    foreach ($segment in $segments)
    {
        $walked += $segment
        $currentPath = $walked -join '/'

        $item = Get-DevOpsQuery -Organization $Organization -ProjectName $ProjectName -Path $currentPath

        if ($null -eq $item)
        {
            Write-Verbose "[Resolve-AzDoQueryPath] Path resolution stopped at '$currentPath' (not found)."
            return $result
        }

        $result.IdChain += $item.id
        $result.Resolved++
        $result.Item = $item
    }

    $result.Exists = ($result.Resolved -eq $segments.Count)

    return $result
}
