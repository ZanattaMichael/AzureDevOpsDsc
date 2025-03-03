Function Remove-AzDoIterationNodes {
    [CmdletBinding()]
    param (
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        # Optional parameter for specifying area paths
        [Parameter()]
        [HashTable[]]$IterationAttributes,

        # Optional hashtable for lookup results
        [Parameter()]
        [HashTable]$LookupResult,

        # Optional parameter to ensure state
        [Parameter()]
        [Ensure]$Ensure,

        # Switch parameter to force execution
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    # Retrieve the global organization name
    $OrganizationName = $Global:DSCAZDO_OrganizationName

    # Iterate through each of the LookupResult nodes and remove them
    ForEach($node in (@($LookupResult.propertiesChanged.ToRemove) | Sort-Object -Descending)) {

        # Reformat the Path
        $reformat = $node.path.Replace('\', '/')
        $Path = $reformat.Replace("/$ProjectName/Iteration/", '')

        Write-Verbose "[Remove-AzDoIterationNodes] Attempting to remove Iteration Node: $($node)."
        Write-Verbose "[Remove-AzDoIterationNodes] Formatted Path: $Path"

        $params = @{
            OrganizationName    = $OrganizationName
            ProjectName         = $ProjectName
            StructureType       = 'Iterations'
            Path                = $path
            ReclassificationId  = $projectAreaId
        }

        Remove-ClassificationNode @params

        Write-Verbose "[Remove-AzDoIterationNodes] Key To Remove: $($node)"
        Remove-CacheItem -Key $node -Type 'LiveIterations'

        Write-Verbose "[Remove-AzDoIterationNodes] Successfully removed Iteration Node: $($node)."

    }

    Write-Verbose "[Remove-AzDoAreaNode] Writing to the updated cache"

    # Write the updated cache to the global cache and export to the cache file.
    Set-CacheObject -Content $Global:AzDoLiveIterations -CacheType 'LiveIterations'
    Refresh-CacheObject -CacheType 'LiveIterations'

}
