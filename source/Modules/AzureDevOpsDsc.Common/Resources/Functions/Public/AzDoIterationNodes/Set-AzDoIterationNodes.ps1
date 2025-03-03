Function Set-AzDoIterationNodes {
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

    # If there are properties to add, call Set-AzDoIterationNodes
    # If there are properties to remove, call Remove-AzDoIterationNodes
    if ($LookupResult.propertiesChanged.toAdd.count -ne 0) {
        # Call Set-AzDoIterationNodes
        Get-AzDoIterationNodes @PSBoundParameters
    }
    if ($LookupResult.propertiesChanged.toRemove.count -ne 0) {
        # Call Remove-AzDoIterationNodes
        Remove-AzDoIterationNodes @PSBoundParameters
    }

    # Iterate through each of the toUpdate properties.
    ForEach ($node in $LookupResult.propertiesChanged.toUpdate) {

        # Switch the path slashes
        $areaPath = $node.Path.Replace('\', '/')
        # Remove the Project and Area prefix from the path
        $removedPrefix = $areaPath.Replace("/$ProjectName/Iteration/", '')
        # Split the path into an array
        $SplitPath = $removedPrefix.Split('/')

        # Define the parameters
        $params = @{
            OrganizationName    = $OrganizationName
            ProjectName         = $ProjectName
            StructureType       = 'Iterations'
            Path = $(
                if ($SplitPath.Count -eq 1) {
                    $null
                }
                else {
                    $SplitPath[0..($SplitPath.Length - 2)] -join '/'
                }
            )
            Body = @{
                attributes = @{
                    startDate  = (Get-Date $node.StartDate).ToString('yyyy-MM-ddT00:00:00Z')
                    finishDate = (Get-Date $node.EndDate).ToString('yyyy-MM-ddT00:00:00Z')
                }
            }
        }

        # If there is a startdate and endDate update the body.
        if ((-not($params.Body.attributes.startDate)) -or (-not($params.Body.attributes.startDate))) {
            # Write an error. There should of been a start and end date here
            Write-Error "[Set-AzDoIterationNodes] Error. startDate and finishDate properties are missing. Skipping."
            continue
        }

        Write-Verbose "[Set-AzDoIterationNodes] Attempting to update Iteration Node: $($node.Path)."
        $response = Update-ClassificationNode @params

        # If the response contains a value, add it to the live cache
        if ($response) {
            Write-Verbose "[Set-AzDoIterationNodes] Successfully updated Iteration Node: $($node.Path), updating live cache."
            # Remove the cache item
            Remove-CacheItem -Key $node.Path -Type 'LiveIterations'
            Add-CacheItem -Type 'LiveIterations' -Key $node.Path -Value $response
        } else {
            Write-Error "[Set-AzDoIterationNodes] Failed to update Iteration Node: $($node.Path)."
            # Stop and Return
            return
        }

    }

    # Write the updated cache to the global cache and export to the cache file.
    Write-Verbose "[Set-AzDoIterationNodes] Updating global cache for LiveIterations."
    Set-CacheObject -Content $Global:AzDoLiveIterations -CacheType 'LiveIterations'
    Refresh-CacheObject -CacheType 'LiveIterations'

    Write-Verbose "[Set-AzDoIterationNodes] Function execution completed for Project: $ProjectName."


}
