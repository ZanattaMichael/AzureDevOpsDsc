Function Remove-AzDoAreaNodes
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $false)]
        [System.String[]]$AreaPaths,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Write-Verbose "[Remove-AzDoAreaNodes] Starting function execution for Project: $ProjectName."

    $OrganizationName = $Global:DSCAZDO_OrganizationName
    # Get the ID of the top-level area. This is needed to get the id so all the work items can be reassigned to the top level area.
    $projectAreaId = ($LookupResult.cachedAreaNodes | Where-Object { $_.path -eq "\$ProjectName\Area" }).id

    Write-Verbose "[Remove-AzDoAreaNodes] Retrieved top-level area node for Project: $ProjectName."
    Write-Verbose "[Remove-AzDoAreaNodes] Project ID: $($projectAreaId)"

    # If the ProjectAreaId is missing, log an error and stop.
    if ($null -eq $projectAreaId) {
        Write-Error "[Remove-AzDoAreaNodes] Stopping. Cannot Enumerate ProjectAreaId for \$ProjectName\Area"
        return
    }

    # Iterate through each of the LookupResult nodes and remove them
    ForEach($node in (@($LookupResult.propertiesChanged.ToDelete) | Sort-Object -Descending)) {

        # Reformat the Path
        $reformat = $node.Replace('\', '/')
        $Path = $reformat.Replace("/$ProjectName/Area/", '')

        Write-Verbose "[Remove-AzDoAreaNodes] Attempting to remove Area Node: $($node)."
        Write-Verbose "[Remove-AzDoAreaNodes] Formatted Path: $Path"
        $params = @{
            OrganizationName    = $OrganizationName
            ProjectName         = $ProjectName
            StructureType       = 'Areas'
            Path                = $path
            ReclassificationId  = $projectAreaId
        }

        Remove-ClassificationNode @params

        Write-Verbose "[Remove-AzDoAreaNodes] Key To Remove: $($node)"
        Remove-CacheItem -Key $node -Type 'LiveAreaNodes'

        Write-Verbose "[Remove-AzDoAreaNodes] Successfully removed Area Node: $($node)."

    }

    Write-Verbose "[Remove-AzDoAreaNode] Writing to the updated cache"

    # Write the updated cache to the global cache and export to the cache file.
    Set-CacheObject -Content $Global:AzDoLiveAreaNodes -CacheType 'LiveAreaNodes'
    Refresh-CacheObject -CacheType 'LiveAreaNodes'

}
