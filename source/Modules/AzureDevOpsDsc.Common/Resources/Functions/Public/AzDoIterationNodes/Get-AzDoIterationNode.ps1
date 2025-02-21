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

    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [Alias('Attributes')]
    [HashTable[]]$IterationAttributes

    # Log the start of function execution with verbose output
    Write-Verbose "[Get-AzDoIterationNode] Start function execution"
    Write-Verbose "[Get-AzDoIterationNode] ProjectName: $ProjectName"
    Write-Verbose "[Get-AzDoIterationNode] IterationAttributes: $($IterationAttributes | Out-String)"

    <#
        Iteration Attributoes

        @{
            Path = ''
            StartDate = ''
            EndDate = ''
        }
    #>

    # Test the Attribute State. Errors will be flagged in the function
    $result = Test-IterationNodeHashTable -IterationAttributes $IterationAttributes
    if (-not $result) { return }

    # Format the provided area paths for the specified project. Add missing classification node paths
    $FormattedIterationAttributes = $IterationAttributes | Format-AzDoIterationPath -ProjectName $ProjectName
    # Extract all Classification Node Paths and match the output to IterationAttributes. If there are any missing, add them.
    $IterationAttributes = $FormattedIterationAttributes.Path | Get-AllAzDoClassificationNodePaths | ForEach-Object {
        $path = $_
        $state = @($FormattedIterationAttributes | Where-Object { $_.path -eq $path })
        if ($state.count -eq 0) {
            # Add the entry
            $FormattedIterationAttributes += @{
                Path = $path
            }
        }
    } | Sort-Object -Property Path

    $classificationNodes = $ | Get-AllAzDoClassificationNodePaths
    Write-Verbose "[Get-AzDoIterationNode] FormattedAreaPaths $($AreaPaths | Out-String)"

    # Retrieve the global organization name
    $OrganizationName = $Global:DSCAZDO_OrganizationName

    # Initialize the result object with default values
    $getAreaResult = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @{
            toAdd = @()
            toRemove = @()
        }
        ProjectName = $ProjectName
        AreaPaths = $AreaPaths
        Status = [DSCGetSummaryState]::Unchanged
        Reason = $null
        CachedAreaNodes = $null
    }

    # Retrieve cached area nodes from cache
    $cachedAreaNodes = (Get-CacheObject -CacheType 'LiveAreaNodes' | Where-Object { $_.Key -like "\$ProjectName\Area*" }).Value

    # Set the cached area nodes in the result object for use by other functions
    $getAreaResult.cachedAreaNodes = $cachedAreaNodes

    # We only need the path to perform the comparison.
    $cachedAreaNodesPath = $cachedAreaNodes.path


    # Check if the cached area nodes contain a top-level node
    $isTopLevel = $cachedAreaNodesPath | Where-Object { $_ -eq "\$ProjectName\Area" }

    # Handle case where no area paths are specified and only top-level node exists
    if ($AreaPaths.Count -eq 0 -and $cachedAreaNodesPath.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoIterationNode] AreaPaths is not specified and no Area Nodes exist in cache"

        $getAreaResult.status = [DSCGetSummaryState]::Unchanged
        $getAreaResult.reason = 'Area Node does not exist and only the top level Area Node exists'

        return $getAreaResult
    }

    # Handle case where no area paths are specified
    if ($AreaPaths.Count -eq 0) {
        Write-Verbose "[Get-AzDoIterationNode] AreaPaths is not specified"

        $getAreaResult.status = [DSCGetSummaryState]::Missing
        $getAreaResult.reason = 'Area Node does not exist'

        if ($Ensure -eq [Ensure]::Absent) {
            $getAreaResult.status = [DSCGetSummaryState]::NotFound
            $getAreaResult.propertiesChanged.toAdd = $cachedAreaNodesPath | Where-Object { $_ -ne "\$ProjectName\Area" }
        } else {
            $getAreaResult.propertiesChanged.Delete = $cachedAreaNodesPath | Where-Object { $_ -ne "\$ProjectName\Area" }
        }

        return $getAreaResult
    }

    # Handle case where only top-level node exists
    if ($cachedAreaNodesPath.Count -eq 1 -and $isTopLevel) {

        Write-Verbose "[Get-AzDoIterationNode] Area Node does not exist"
        $getAreaResult.status = [DSCGetSummaryState]::NotFound

        if ($Ensure -eq [Ensure]::Absent) {
            $getAreaResult.status = [DSCGetSummaryState]::Missing
            $getAreaResult.propertiesChanged.toDelete = $AreaPaths | Where-Object { $_ -ne "\$ProjectName\Area" }
        } else {
            $getAreaResult.propertiesChanged.toAdd = $AreaPaths | Where-Object { $_ -ne "\$ProjectName\Area" }
        }

        $getAreaResult.reason = 'Area Node does not exist'

        return $getAreaResult
    }

    # Extract paths from cached area nodes for comparison
    $differenceObject = $cachedAreaNodesPath

    # Compare current and desired area paths, excluding top-level areas
    $currentList = Compare-Object -ReferenceObject $AreaPaths -DifferenceObject $differenceObject -IncludeEqual | Where-Object {
        $_.InputObject -ne "\$ProjectName\Area"
    }

    # Determine actions based on Ensure parameter
    if ($Ensure -eq [Ensure]::Absent) {
        # Identify items present in both lists for removal
        $toDelete = ($currentList | Where-Object {
            ($_.SideIndicator -eq '==')
        }).InputObject

    } else {
        # Identify items missing in current or desired state
        $toAdd = ($currentList | Where-Object { $_.SideIndicator -eq '<=' }).InputObject
        $toDelete = ($currentList | Where-Object { $_.SideIndicator -eq '=>' }).InputObject
    }

    # Update status based on differences between current and desired states
    if (($toDelete.count -ne 0) -and ($toAdd.count -ne 0)) {
        $getAreaResult.status = [DSCGetSummaryState]::Changed
    }
    elseif ($toDelete.count -ne 0) {
        $getAreaResult.status = [DSCGetSummaryState]::Missing
    }
    elseif ($toAdd.count -ne 0) {
        $getAreaResult.status = [DSCGetSummaryState]::NotFound
    }

    # Update propertiesChanged with determined additions and deletions
    $getAreaResult.propertiesChanged = @{
        toDelete = $toDelete
        toAdd = $toAdd
    }

    # Return the result object with all computed information
    return $getAreaResult

}

