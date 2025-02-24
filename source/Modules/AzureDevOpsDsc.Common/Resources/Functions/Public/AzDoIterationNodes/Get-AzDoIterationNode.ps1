Function Get-AzDoIterationNode {
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
    $FormattedIterationAttributesPath = $FormattedIterationAttributes.Path

    Write-Verbose "[Get-AzDoIterationNode] FormattedIterationAttributesPath $($IterationAttributesPath | Out-String)"


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

    # Retrieve cached area nodes from cache
    $cachedIterationNodes = (Get-CacheObject -CacheType 'LiveIterationNodes' | Where-Object { $_.Key -like "\$ProjectName\Iteration*" }).Value
    $cachedIterationNodesPath = $cachedIterationNodes.Path

    # Set the cached area nodes in the result object for use by other functions
    $getIterationResult.CachedIterationNodes = $cachedIterationNodes

    # Check if the cached area nodes contain a top-level node
    $isTopLevel = $cachedIterationNodesPath | Where-Object { $_ -eq "\$ProjectName\Iteration" }

    # Handle case where no area paths are specified and only top-level node exists
    if ($FormattedIterationAttributesPath.Count -eq 0 -and $cachedIterationNodesPath.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoIterationNode] IterationAttributesPath is not specified and no Area Nodes exist in cache"

        $getIterationResult.status = [DSCGetSummaryState]::Unchanged
        $getIterationResult.reason = 'Iteration Node does not exist and only the top level Area Node exists'

        return $getIterationResult
    }

    # Handle case where no area paths are specified
    if ($IterationAttributesPath.Count -eq 0) {
        Write-Verbose "[Get-AzDoIterationNode] IterationAttributesPath is not specified"

        $getIterationResult.status = [DSCGetSummaryState]::Missing
        $getIterationResult.reason = 'Area Node does not exist'

        if ($Ensure -eq [Ensure]::Absent) {
            $getIterationResult.status = [DSCGetSummaryState]::NotFound
            $getIterationResult.propertiesChanged.toAdd = $cachedIterationNodes | Where-Object { $_.value.Path -ne "\$ProjectName\Iteration" }
        } else {
            $getIterationResult.propertiesChanged.Delete = $cachedIterationNodes | Where-Object { $_.value.Path -ne "\$ProjectName\Iteration" }
        }

        return $getIterationResult
    }

    # Handle case where only top-level node exists
    if ($cachedIterationNodesPath.Count -eq 1 -and $isTopLevel) {

        Write-Verbose "[Get-AzDoIterationNode] Area Node does not exist"
        $getIterationResult.status = [DSCGetSummaryState]::NotFound

        if ($Ensure -eq [Ensure]::Absent) {
            $getIterationResult.status = [DSCGetSummaryState]::Missing
            $getIterationResult.propertiesChanged.toDelete = $FormattedIterationAttributes | Where-Object { $_.path -ne "\$ProjectName\Iteration" }
        } else {
            $getIterationResult.propertiesChanged.toAdd = $FormattedIterationAttributes | Where-Object { $_.path -ne "\$ProjectName\Iteration" }
        }

        $getIterationResult.reason = 'Area Node does not exist'

        return $getIterationResult
    }

    #
    # Iterate Through the Cached Iteration Nodes

    ForEach ($node in $cachedIterationNodes.value) {

        # Attempt to perform a lookup and find the corrosponding path in FormattedIterationAttributes
        $matched = @($FormattedIterationAttributes | Where-Object { $_.Path -eq $node.Path })
        # Test if the result has been matched.
        if ($matched.Count -eq 1) {

            # If ensure is absent and it's present in the source list. Delete!
            if ($Ensure -eq [Ensure]::Absent) {
                $getIterationResult.propertiesChanged.toDelete += $node
                continue
            }

            # Only process the following if ensure is set to present.
            $params = @{
                ReferenceHashTable = $node
                DifferenceHashTable = $matched
                Keys = @('StartDate','EndDate')
            }

            # If the Properties are different, flag and move on.
            if (-not(Compare-HashtableProperties @params)) {
                $getIterationResult.propertiesChanged.ToUpdate += $node
                # Move on
                continue
            }

            # Format the DateTime into a common format and compare
            $cachedStartDate    = ($ReferenceHashTable.StartDate -as [datetime]).ToString('yyyyMMdd')
            $cachedEndDate      = ($ReferenceHashTable.EndDate -as [datetime]).ToString('yyyyMMdd')
            $matchedStartDate   = ($matched.StartDate -as [datetime]).ToString('yyyyMMdd')
            $matchedEndDate     = ($matched.EndDate -as [datetime]).ToString('yyyyMMdd')

            # If the datetime's (dates in this case) have changed, it needs to be updated.
            if (
                ($cachedStartDate -xor $matchedStartDate) -or
                ($cachedEndDate -xor $matchedEndDate)
            ) {
                $getIterationResult.propertiesChanged.ToUpdate += $node
            }
            # Move to the next item
            continue
        }

        # Depending on what ensure is doing will depend on the outcome
        if ($Ensure -eq [Ensrue]::Absent) {
            # It's not present in the source list so it's unchanged
            continue
        } else {
            # It's not present in the source list but it's active - delete it.
            $getIterationResult.propertiesChanged.toDelete += $node
            continue
        }

    }

    #
    # Switch and compare the Desired Input list with the cache.

    ForEach ($node in $FormattedIterationAttributes) {

        # Attempt to perform a lookup and find the corrosponding path in FormattedIterationAttributes
        $matched = @($cachedIterationNodes.value | Where-Object { $_.Path -eq $node.Path })
        # Test if the result has been matched.
        if ($matched.Count -eq 1) {
            # We don't need to test the properties since they were tested in the earlier look. Continue
            continue
        }

        # Depending on what ensure is doing will depend on the outcome
        if ($Ensure -eq [Ensrue]::Absent) {
            # It's present in the source list but not online
            continue
        } else {
            # It's not present online but defined in the source list. Add it.
            $getIterationResult.propertiesChanged.toAdd += $node
            continue
        }

    }

    # Update status based on differences between current and desired states
    if ($getIterationResult.propertiesChanged.ToUpdate.count -ge 0) {
        $getIterationResult.status = [DSCGetSummaryState]::Changed
    }
    elseif ($getIterationResult.propertiesChanged.toDelete.count -ne 0) {
        $getIterationResult.status = [DSCGetSummaryState]::Missing
    }
    elseif ($getIterationResult.propertiesChanged.toAdd.count -ne 0) {
        $getIterationResult.status = [DSCGetSummaryState]::NotFound
    }

    # Return the result object with all computed information
    return $getIterationResult

}

