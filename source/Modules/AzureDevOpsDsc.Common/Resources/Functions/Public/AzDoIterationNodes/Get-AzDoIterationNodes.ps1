<#
.SYNOPSIS
    Retrieves and processes Azure DevOps Iteration Nodes for a specified project.

.DESCRIPTION
    The Get-AzDoIterationNodes function retrieves and processes Azure DevOps Iteration Nodes for a specified project.
    It compares the current state of iteration nodes with the desired state and returns the differences.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER IterationAttributes
    An optional hashtable array specifying the attributes of the iterations, such as Path, StartDate, and EndDate.

.PARAMETER LookupResult
    An optional hashtable for lookup results.

.PARAMETER Ensure
    An optional parameter to specify the desired state of the iteration nodes.
    Possible values are 'Present' or 'Absent'.

.PARAMETER Force
    A switch parameter to force the execution of the function.

.EXAMPLE
    Get-AzDoIterationNodes -ProjectName "MyProject" -IterationAttributes @(@{Path="Iteration1"; StartDate="2023-01-01"; EndDate="2023-01-31"})

    Retrieves and processes the iteration nodes for the project "MyProject" with the specified iteration attributes.

.EXAMPLE
    Get-AzDoIterationNodes -ProjectName "MyProject" -Ensure Present

    Ensures that the iteration nodes for the project "MyProject" are present.

.NOTES
    This function requires the global variable (Get-AzDoOrganizationName) to be set with the organization name.
    The function uses cached iteration nodes and compares them with the desired state to determine the necessary changes.

#>
Function Get-AzDoIterationNodes {
    [CmdletBinding()]
    param (
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        # Optional parameter for specifying Iteration paths
        [Parameter()]
        [object[]]$IterationAttributes,

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
    $OrganizationName = (Get-AzDoOrganizationName)

    # Log the start of function execution with verbose output
    Write-Verbose "[Get-AzDoIterationNodes] Start function execution"
    Write-Verbose "[Get-AzDoIterationNodes] ProjectName: $ProjectName"
    Write-Verbose "[Get-AzDoIterationNodes] IterationAttributes: $($IterationAttributes | Out-String)"

    <#
        Iteration Attributes

        @{
            Path = ''
            StartDate = ''
            EndDate = ''
        }
    #>

    $FormattedIterationAttributes = Format-AzDoIterationNodes -IterationAttributes $IterationAttributes -ProjectName $ProjectName
    Write-Verbose "[Get-AzDoIterationNodes] FormattedIterationAttributesPath $($FormattedIterationAttributes | ConvertTo-Json)"

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
    Write-Verbose "[Get-AzDoIterationNodes] Retrieving cached Iteration nodes"
    $cachedIterationNodes = ((Get-CacheObject -CacheType 'LiveIterations') | Where-Object { $_.Key -like "\$ProjectName\Iteration*" }).Value
    $cachedIterationNodesPath = $cachedIterationNodes.Path

    # Set the cached Iteration nodes in the result object for use by other functions
    $getIterationResult.CachedIterationNodes = $cachedIterationNodes

    # Check if the cached Iteration nodes contain a top-level node
    $isTopLevel = $cachedIterationNodesPath | Where-Object { $_ -eq "\$ProjectName\Iteration" }

    # Handle case where no Iteration paths are specified and only top-level node exists
    if ($FormattedIterationAttributes.Count -eq 0 -and $cachedIterationNodesPath.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoIterationNodes] IterationAttributesPath is not specified and no Iteration Nodes exist in cache"

        $getIterationResult.status = [DSCGetSummaryState]::Unchanged
        $getIterationResult.reason = 'Iteration Node does not exist and only the top level Iteration Node exists'

        return $getIterationResult
    }

    # Handle case where no Iteration paths are specified
    if ($FormattedIterationAttributes.Count -eq 0) {

        Write-Verbose "[Get-AzDoIterationNodes] IterationAttributesPath is not specified"
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

        Write-Verbose "[Get-AzDoIterationNodes] Cached Iteration Nodes does not exist"
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

    #
    # Both lists are indexed by path once, so matching a node against the other list is one
    # lookup instead of a scan of that list for every node. Paths are compared the way '-eq'
    # compares strings. A list holding a path that is not a string is not indexed and is
    # scanned as before.
    $indexByPath = {
        param ($Nodes)

        $index = [System.Collections.Generic.Dictionary[System.String, System.Collections.Generic.List[System.Object]]]::new([System.StringComparer]::InvariantCultureIgnoreCase)
        foreach ($indexedNode in $Nodes)
        {
            if ($indexedNode.Path -isnot [System.String]) { return $null }

            $bucket = $null
            if (-not $index.TryGetValue($indexedNode.Path, [ref]$bucket))
            {
                $bucket = [System.Collections.Generic.List[System.Object]]::new()
                $index[$indexedNode.Path] = $bucket
            }
            $bucket.Add($indexedNode)
        }

        return $index
    }

    $findByPath = {
        param ($Index, $Nodes, $Path)

        if (($null -eq $Index) -or ($Path -isnot [System.String]))
        {
            return @($Nodes | Where-Object { $_.Path -eq $Path })
        }

        $bucket = $null
        if ($Index.TryGetValue($Path, [ref]$bucket)) { return $bucket.ToArray() }
        return @()
    }

    $desiredNodesByPath = & $indexByPath $formattedIterationNodes
    $cachedNodesByPath  = & $indexByPath $formattedCachedIterationNodes

    $nodesToRemove = [System.Collections.Generic.List[System.Object]]::new()
    $nodesToUpdate = [System.Collections.Generic.List[System.Object]]::new()
    $nodesToAdd    = [System.Collections.Generic.List[System.Object]]::new()

    # Iterate Through the Cached Iteration Nodes
    ForEach ($node in $formattedCachedIterationNodes) {
        Write-Verbose "[Get-AzDoIterationNodes] Processing cached node: $($node.Path)"

        # Attempt to perform a lookup and find the corresponding path in FormattedIterationAttributes
        $matched = @(& $findByPath $desiredNodesByPath $formattedIterationNodes $node.Path)
        # Test if the result has been matched.

        if ($matched.Count -eq 1) {
            Write-Verbose "[Get-AzDoIterationNodes] Found matching node: $($matched.Path)"

            # If ensure is absent and it's present in the source list. Delete!
            if ($Ensure -eq [Ensure]::Absent) {
                $nodesToRemove.Add($node)
                continue
            }

            # Only process the following if ensure is set to present.
            # Azure DevOps API stores dates nested under attributes.startDate/finishDate.
            $nodeStartDate = if ($node.attributes) { $node.attributes.startDate } else { $null }
            $nodeEndDate   = if ($node.attributes) { $node.attributes.finishDate } else { $null }
            $matchedNode   = $matched[0]

            # Normalize dates to a common format before comparing to avoid type mismatches
            # (e.g. Deserialized.System.DateTime from cache vs string from desired state).
            $cachedStartDate  = Format-Date $nodeStartDate
            $cachedEndDate    = Format-Date $nodeEndDate
            $matchedStartDate = Format-Date $matchedNode.StartDate
            $matchedEndDate   = Format-Date $matchedNode.EndDate

            Write-Verbose "[Get-AzDoIterationNodes] Comparing dates: cached=[$cachedStartDate/$cachedEndDate] desired=[$matchedStartDate/$matchedEndDate]"

            if (($cachedStartDate -ne $matchedStartDate) -or ($cachedEndDate -ne $matchedEndDate)) {
                Write-Verbose "[Get-AzDoIterationNodes] DateTimes differ, updating node: $($node.Path)"
                $nodesToUpdate.Add(@{
                    StartDate = $matchedNode.StartDate
                    EndDate   = $matchedNode.EndDate
                    Path      = $matchedNode.Path
                })
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
            Write-Verbose "[Get-AzDoIterationNodes] Node not in source list, deleting: $($node.Path)"
            $nodesToRemove.Add($node)
            continue
        }
    }

    # Switch and compare the Desired Input list with the cache.
    ForEach ($node in $formattedIterationNodes) {
        Write-Verbose "[Get-AzDoIterationNodes] Processing formatted node: $($node.Path)"

        # Attempt to perform a lookup and find the corresponding path in FormattedIterationAttributes
        $matched = @(& $findByPath $cachedNodesByPath $formattedCachedIterationNodes $node.Path)
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
            Write-Verbose "[Get-AzDoIterationNodes] Node not online, adding: $($node.Path)"
            $nodesToAdd.Add($node)
            continue
        }
    }

    $getIterationResult.propertiesChanged.toRemove = $nodesToRemove.ToArray()
    $getIterationResult.propertiesChanged.toUpdate = $nodesToUpdate.ToArray()
    $getIterationResult.propertiesChanged.toAdd    = $nodesToAdd.ToArray()

    # Update status based on differences between current and desired states
    if ($getIterationResult.propertiesChanged.ToUpdate.count -ne 0) {
        Write-Verbose "[Get-AzDoIterationNodes] Changes detected, status set to Changed."
        $getIterationResult.status = [DSCGetSummaryState]::Changed
    }
    elseif (($getIterationResult.propertiesChanged.toRemove.count -ne 0) -and ($getIterationResult.propertiesChanged.toAdd.count -ne 0)) {
        Write-Verbose "[Get-AzDoIterationNodes] Both ToAdd to ToRemove properties contain values."
        $getIterationResult.status = [DSCGetSummaryState]::Changed
    }
    elseif ($getIterationResult.propertiesChanged.toRemove.count -ne 0) {
        Write-Verbose "[Get-AzDoIterationNodes] Some nodes missing, status set to Missing."
        $getIterationResult.status = [DSCGetSummaryState]::Missing
    }
    elseif ($getIterationResult.propertiesChanged.toAdd.count -ne 0) {
        Write-Verbose "[Get-AzDoIterationNodes] Some nodes not found, status set to NotFound."
        $getIterationResult.status = [DSCGetSummaryState]::NotFound
    }

    # Return the result object with all computed information
    Write-Verbose "[Get-AzDoIterationNodes] Function execution completed"
    return $getIterationResult


}

