Function Set-AzDoAreaNodes {
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

    Write-Verbose "[Set-AzDoAreaNodes] Starting function execution for Project: $ProjectName."

    $OrganizationName = $Global:DSCAZDO_OrganizationName

    # Get the ID of the top-level area. This is needed to get the id so all the work items can be reassigned to the top level area.
    $projectArea = $LookupResult.cachedAreaNodes | Where-Object { $_.Key -eq "$ProjectName\Area" }

    Write-Verbose "[Set-AzDoAreaNodes] Retrieved top-level area node for Project: $ProjectName."

    # Iterate through the LookupResult hashtable and process the values.
    # Sort the values to ensure that the parent nodes are created before the child nodes.
    ForEach ($areaPathToAdd in ($LookupResult.ToAdd | Sort-Object)) {

        # Remove the Project and Area prefix from the path
        $removedPrefix = $areaPathToAdd -replace "\$Project\Area\", ''
        # Split the path into an array
        $SplitPath = $removedPrefix -split '\'

        # Construct the parameters for the New-ClassificationNode function
        $params = @{
            OrganizationName = $OrganizationName
            ProjectName = $ProjectName
            StructureType = 'Area'
            Path = $(
                if ($SplitPath.Count -eq 1) {
                    $null
                }
                else {
                    $SplitPath[0..($SplitPath.Length - 2)] -join '/'
                }
            )
            Body = @{
                name = $SplitPath[-1]
            }
        }

        Write-Verbose "[Set-AzDoAreaNodes] Attempting to create Area Node: $($areaPathToAdd)."
        $response = New-ClassificationNode @params

        # If the response contains a value, add it to the live cache
        if ($response) {
            Write-Verbose "[Set-AzDoAreaNodes] Successfully created Area Node: $($areaPathToAdd), updating live cache."
            Add-CacheObject -CacheType 'LiveAreaNodes' -Key "$ProjectName\Area\" -Value $response
        } else {
            Write-Verbose "[Set-AzDoAreaNodes] Failed to create Area Node: $($areaPathToAdd)."
        }
    }

    # Iterate through each of the LookupResult nodes and remove them
    ForEach($node in $LookupResult.ToRemove) {
        Write-Verbose "[Set-AzDoAreaNodes] Attempting to remove Area Node: $($node)."
        $params = @{
            OrganizationName    = $OrganizationName
            ProjectName         = $ProjectName
            StructureType       = 'Area'
            Path                = $node
            ReclassificationId  = $projectArea.value.id
        }

        Remove-ClassificationNode @params
        Remove-CacheItem -Key "$ProjectName\Area\" -Type 'LiveAreaNodes'

        Write-Verbose "[Set-AzDoAreaNodes] Successfully removed Area Node: $($node)."
    }

    # Write the updated cache to the global cache and export to the cache file.
    Write-Verbose "[Set-AzDoAreaNodes] Updating global cache for LiveAreaNodes."
    Set-CacheObject -Content $Global:AzDoLiveAreaNodes -CacheType 'LiveAreaNodes'

    Write-Verbose "[Set-AzDoAreaNodes] Function execution completed for Project: $ProjectName."
}
