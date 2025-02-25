Function Get-AzDoIterationNodes {
    [CmdletBinding()]
    param (
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        # Optional parameter for specifying Iteration paths
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

    # Log the start of function execution with verbose output
    Write-Verbose "[Get-AzDoIterationNode] Start function execution"
    Write-Verbose "[Get-AzDoIterationNode] ProjectName: $ProjectName"
    Write-Verbose "[Get-AzDoIterationNode] IterationAttributes: $($IterationAttributes | Out-String)"

    <#
        Iteration Attributes

        @{
            Path = ''
            StartDate = ''
            EndDate = ''
        }
    #>

    $FormattedIterationAttributes = Format-AzDoIterationNodes -IterationAttributes $IterationAttributes -ProjectName $ProjectName
    Write-Verbose "[Get-AzDoIterationNode] FormattedIterationAttributesPath $($FormattedIterationAttributes | ConvertTo-Json)"

    # Initialize the result object with default values
    $getIterationResult = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @{
            toAdd = @()
            toRemove = @()
            toUpdate = @()
        }
        ProjectName = $ProjectName
        IterationAttributes = $FormattedIterationAttributes
        CachedIterationNodes = $null
        Status = [DSCGetSummaryState]::Unchanged
        Reason = $null
    }

    # Retrieve cached Iteration nodes from cache
    Write-Verbose "[Get-AzDoIterationNode] Retrieving cached Iteration nodes"
    $cachedIterationNodes = (Get-CacheObject -CacheType 'LiveIterations' | Where-Object { $_.Key -like "\$ProjectName\Iteration*" }).Value
    $cachedIterationNodesPath = $cachedIterationNodes.Path

    # Set the cached Iteration nodes in the result object for use by other functions
    $getIterationResult.CachedIterationNodes = $cachedIterationNodes

    # Check if the cached Iteration nodes contain a top-level node
    $isTopLevel = $cachedIterationNodesPath | Where-Object { $_ -eq "\$ProjectName\Iteration" }

    # Handle case where no Iteration paths are specified and only top-level node exists
    if ($FormattedIterationAttributes.Count -eq 0 -and $cachedIterationNodesPath.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoIterationNode] IterationAttributesPath is not specified and no Iteration Nodes exist in cache"

        $getIterationResult.status = [DSCGetSummaryState]::Unchanged
        $getIterationResult.reason = 'Iteration Node does not exist and only the top level Iteration Node exists'

        return $getIterationResult
    }

    # Handle case where no Iteration paths are specified
    if ($FormattedIterationAttributes.Count -eq 0) {

        Write-Verbose "[Get-AzDoIterationNode] IterationAttributesPath is not specified"
        $getIterationResult.status = [DSCGetSummaryState]::Missing
        $getIterationResult.reason = 'Desired State Iterations Node does not exist'

        if ($Ensure -eq [Ensure]::Absent) {
            $getIterationResult.status = [DSCGetSummaryState]::NotFound
            $getIterationResult.propertiesChanged.toAdd = $cachedIterationNodes | Where-Object { $_.Path -ne "\$ProjectName\Iteration" }
        } else {
            $getIterationResult.propertiesChanged.toRemove = $cachedIterationNodes | Where-Object { $_.Path -ne "\$ProjectName\Iteration" }
        }

        return $getIterationResult

    }

    # Handle case where only top-level node exists
    if ($cachedIterationNodes.Count -eq 1 -and $isTopLevel) {

        Write-Verbose "[Get-AzDoIterationNode] Cached Iteration Nodes does not exist"
        $getIterationResult.status = [DSCGetSummaryState]::NotFound

        if ($Ensure -eq [Ensure]::Absent) {
            $getIterationResult.status = [DSCGetSummaryState]::Missing
            $getIterationResult.propertiesChanged.toRemove = $FormattedIterationAttributes | Where-Object { $_.Path -ne "\$ProjectName\Iteration" }
        } else {
            $getIterationResult.propertiesChanged.toAdd = $FormattedIterationAttributes | Where-Object { $_.Path -ne "\$ProjectName\Iteration" }
        }

        $getIterationResult.reason = 'Iteration Node does not exist'

        return $getIterationResult
    }

    $formattedCachedIterationNodes = $cachedIterationNodes | Where-Object { $_.Path -ne "\$ProjectName\Iteration" }
    $formattedIterationNodes = $FormattedIterationAttributes | Where-Object { $_.Path -ne "\$ProjectName\Iteration" }

    # Iterate Through the Cached Iteration Nodes
    ForEach ($node in $formattedCachedIterationNodes) {
        Write-Verbose "[Get-AzDoIterationNode] Processing cached node: $($node.Path)"

        # Attempt to perform a lookup and find the corresponding path in FormattedIterationAttributes
        $matched = @($formattedIterationNodes | Where-Object { $_.Path -eq $node.Path })
        # Test if the result has been matched.

        if ($matched.Count -eq 1) {
            Write-Verbose "[Get-AzDoIterationNode] Found matching node: $($matched.Path)"

            # If ensure is absent and it's present in the source list. Delete!
            if ($Ensure -eq [Ensure]::Absent) {
                $getIterationResult.propertiesChanged.toRemove += $node
                continue
            }

            # Only process the following if ensure is set to present.
            $params = @{
                ReferenceHashTable = $node
                DifferenceHashTable = @{
                    StartDate = $matched.StartDate
                    EndDate = $matched.EndDate
                    Path = $matched.Path
                }
                Keys = @('StartDate','EndDate')
            }

            $params | Export-Clixml C:\Temp\params.clixml

            # If the Properties are different, flag and move on.
            if (-not(Compare-HashtableProperties @params)) {
                Write-Verbose "[Get-AzDoIterationNode] Properties differ, updating node: $($node.Path)"
                $getIterationResult.propertiesChanged.ToUpdate += $node
                # Move on
                continue
            }

            Write-Verbose "[Get-AzDoIterationNode] Formatting Start and End Dates"
            # Format the DateTime into a common format and compare
            $cachedStartDate    = Format-Date $ReferenceHashTable.StartDate
            $cachedEndDate      = Format-Date $ReferenceHashTable.StartDate
            $matchedStartDate   = Format-Date $matched.StartDate
            $matchedEndDate     = Format-Date $matched.StartDate

            # If the datetime's (dates in this case) have changed, it needs to be updated.
            if (
                ($cachedStartDate -xor $matchedStartDate) -or
                ($cachedEndDate -xor $matchedEndDate)
            ) {
                Write-Verbose "[Get-AzDoIterationNode] DateTimes differ, updating node: $($node.Path)"
                $getIterationResult.propertiesChanged.ToUpdate += $node
            }
            # Move to the next item
            continue
        }

        # Depending on what ensure is doing will depend on the outcome
        if ($Ensure -eq [Ensure]::Absent) {
            # It's not present in the source list so it's unchanged
            continue
        } else {
            # It's not present in the source list but it's active - delete it.
            Write-Verbose "[Get-AzDoIterationNode] Node not in source list, deleting: $($node.Path)"
            $getIterationResult.propertiesChanged.toRemove += $node
            continue
        }
    }

    # Switch and compare the Desired Input list with the cache.
    ForEach ($node in $formattedIterationNodes) {
        Write-Verbose "[Get-AzDoIterationNode] Processing formatted node: $($node.Path)"

        # Attempt to perform a lookup and find the corresponding path in FormattedIterationAttributes
        $matched = @($formattedCachedIterationNodes | Where-Object { $_.Path -eq $node.Path })
        # Test if the result has been matched.
        if ($matched.Count -eq 1) {
            # We don't need to test the properties since they were tested in the earlier look. Continue
            continue
        }

        # Depending on what ensure is doing will depend on the outcome
        if ($Ensure -eq [Ensure]::Absent) {
            # It's present in the source list but not online
            continue
        } else {
            # It's not present online but defined in the source list. Add it.
            Write-Verbose "[Get-AzDoIterationNode] Node not online, adding: $($node.Path)"
            $getIterationResult.propertiesChanged.toAdd += $node
            continue
        }
    }

    # Update status based on differences between current and desired states
    if ($getIterationResult.propertiesChanged.ToUpdate.count -ge 0) {
        Write-Verbose "[Get-AzDoIterationNode] Changes detected, status set to Changed"
        $getIterationResult.status = [DSCGetSummaryState]::Changed
    }
    elseif ($getIterationResult.propertiesChanged.toRemove.count -ne 0) {
        Write-Verbose "[Get-AzDoIterationNode] Some nodes missing, status set to Missing"
        $getIterationResult.status = [DSCGetSummaryState]::Missing
    }
    elseif ($getIterationResult.propertiesChanged.toAdd.count -ne 0) {
        Write-Verbose "[Get-AzDoIterationNode] Some nodes not found, status set to NotFound"
        $getIterationResult.status = [DSCGetSummaryState]::NotFound
    }

    # Return the result object with all computed information
    Write-Verbose "[Get-AzDoIterationNode] Function execution completed"
    return $getIterationResult


}

