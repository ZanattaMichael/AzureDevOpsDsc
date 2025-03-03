Function New-AzDoIterationNodes {
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

    # Iterate Through Each of the LookupResult ToAdd Properties
    ForEach ($node in $LookupResult.propertiesChanged.ToAdd) {

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
                name = $SplitPath[-1]
            }
        }

        # If there is a startdate and endDate update the body.
        if ($node.EndDate -and $node.StartDate) {
            $params.Body.attributes = @{
                startDate  = (Get-Date $node.StartDate).ToString('yyyy-MM-ddT00:00:00Z')
                finishDate = (Get-Date $node.EndDate).ToString('yyyy-MM-ddT00:00:00Z')
            }
        }

        Write-Verbose "[New-AzDoIterationNodes] Attempting to create Iteration Node: $($node.Path)."
        $response = New-ClassificationNode @params

        # If the response contains a value, add it to the live cache
        if ($response) {
            Write-Verbose "[New-AzDoIterationNodes] Successfully created Iteration Node: $($node.Path), updating live cache."
            Add-CacheItem -Type 'LiveIterations' -Key $node.Path -Value $response
        } else {
            Write-Error "[New-AzDoIterationNodes] Failed to create Iteration Node: $($node.Path)."
            # Stop and Return
            return
        }

    }

    # Write the updated cache to the global cache and export to the cache file.
    Write-Verbose "[New-AzDoIterationNodes] Updating global cache for LiveIterations."
    Set-CacheObject -Content $Global:AzDoLiveIterations -CacheType 'LiveIterations'
    Refresh-CacheObject -CacheType 'LiveIterations'

    Write-Verbose "[New-AzDoIterationNodes] Function execution completed for Project: $ProjectName."

}
