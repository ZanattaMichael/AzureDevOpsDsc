<#
.SYNOPSIS
    Retrieves Azure DevOps area nodes for a specified project.

.DESCRIPTION
    The Get-AzDoAreaNodes function retrieves Azure DevOps area nodes for a specified project.
    It formats the provided area paths, retrieves cached area nodes, and compares the current
    and desired area paths to determine the necessary actions based on the Ensure parameter.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER AreaPaths
    An optional array of strings specifying the area paths to be retrieved.

.PARAMETER LookupResult
    An optional hashtable for lookup results.

.PARAMETER Ensure
    An optional parameter to ensure the state of the area nodes. Possible values are 'Present' or 'Absent'.

.PARAMETER Force
    A switch parameter to force the execution of the function.

.EXAMPLE
    Get-AzDoAreaNodes -ProjectName "MyProject" -AreaPaths @("Area1", "Area2")

    Retrieves the area nodes for the specified project "MyProject" with the specified area paths "Area1" and "Area2".

.EXAMPLE
    Get-AzDoAreaNodes -ProjectName "MyProject" -Ensure Absent

    Ensures that the area nodes for the specified project "MyProject" are absent.

.NOTES
    This function uses cached area nodes to determine the current state and compares it with the desired state.
    It returns a result object containing the status, reason, and propertiesChanged based on the comparison.
#>
Function Get-AzDoAreaNodes {
    [CmdletBinding()]
    param (
        # Mandatory parameter for the project name
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        # Optional parameter for specifying area paths
        [Parameter(Mandatory = $false)]
        [System.String[]]$AreaPaths,

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

    # Log the start of function execution with verbose output
    Write-Verbose "[Get-AzDoAreaNodes] Start function execution"
    Write-Verbose "[Get-AzDoAreaNodes] ProjectName: $ProjectName"
    Write-Verbose "[Get-AzDoAreaNodes] AreaPaths: $($AreaPaths | Out-String)"

    # Format the provided area paths for the specified project. Add missing classification node paths
    if ($AreaPaths.Count -ne 0) {
        $AreaPaths = $AreaPaths | Format-AzDoAreaPath -ProjectName $ProjectName | Get-AllAzDoClassificationNodePaths
    }

    Write-Verbose "[Get-AzDoAreaNodes] FormattedAreaPaths $($AreaPaths | Out-String)"

    # Retrieve the global organization name
    $OrganizationName = (Get-AzDoOrganizationName)
    Write-Verbose "[Get-AzDoAreaNodes] OrganizationName: $OrganizationName"

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
    Write-Verbose "[Get-AzDoAreaNodes] Retrieved cached area nodes: $($cachedAreaNodes | Out-String)"

    # Set the cached area nodes in the result object for use by other functions
    $getAreaResult.cachedAreaNodes = $cachedAreaNodes

    # We only need the path to perform the comparison.
    $cachedAreaNodesPath = $cachedAreaNodes.path
    Write-Verbose "[Get-AzDoAreaNodes] Cached area nodes paths: $($cachedAreaNodesPath | Out-String)"

    # Check if the cached area nodes contain a top-level node
    $isTopLevel = $cachedAreaNodesPath | Where-Object { $_ -eq "\$ProjectName\Area" }
    Write-Verbose "[Get-AzDoAreaNodes] Is top-level node present: $isTopLevel"

    # Handle case where no area paths are specified and only top-level node exists
    if ($AreaPaths.Count -eq 0 -and $cachedAreaNodesPath.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoAreaNodes] AreaPaths is not specified and no Area Nodes exist in cache"

        $getAreaResult.status = [DSCGetSummaryState]::Unchanged
        $getAreaResult.reason = 'Area Node does not exist and only the top level Area Node exists'

        return $getAreaResult
    }

    # Handle case where no area paths are specified
    if ($AreaPaths.Count -eq 0) {
        Write-Verbose "[Get-AzDoAreaNodes] AreaPaths is not specified"

        $getAreaResult.status = [DSCGetSummaryState]::Missing
        $getAreaResult.reason = 'Area Node does not exist'

        if ($Ensure -eq [Ensure]::Absent) {
            $getAreaResult.status = [DSCGetSummaryState]::NotFound
            $getAreaResult.propertiesChanged.toAdd = $cachedAreaNodesPath | Where-Object { $_ -ne "\$ProjectName\Area" } | ForEach-Object { @{ Path = $_ } }
        } else {
            $getAreaResult.propertiesChanged.ToRemove = $cachedAreaNodesPath | Where-Object { $_ -ne "\$ProjectName\Area" } | ForEach-Object { @{ Path = $_ } }
        }

        return $getAreaResult
    }

    # Handle case where only top-level node exists
    if ($cachedAreaNodesPath.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoAreaNodes] Only top-level node exists"

        $getAreaResult.status = [DSCGetSummaryState]::NotFound

        if ($Ensure -eq [Ensure]::Absent) {
            $getAreaResult.status = [DSCGetSummaryState]::Missing
            $getAreaResult.propertiesChanged.toRemove = $AreaPaths | Where-Object { $_ -ne "\$ProjectName\Area" } | ForEach-Object { @{ Path = $_ } }
        } else {
            $getAreaResult.propertiesChanged.toAdd = $AreaPaths | Where-Object { $_ -ne "\$ProjectName\Area" } | ForEach-Object { @{ Path = $_ } }
        }

        $getAreaResult.reason = 'Area Node does not exist'

        return $getAreaResult
    }

    # Extract paths from cached area nodes for comparison
    $differenceObject = $cachedAreaNodesPath
    Write-Verbose "[Get-AzDoAreaNodes] Difference object for comparison: $($differenceObject | Out-String)"

    # Compare current and desired area paths, excluding top-level areas
    $currentList = Compare-Object -ReferenceObject $AreaPaths -DifferenceObject $differenceObject -IncludeEqual | Where-Object {
        $_.InputObject -ne "\$ProjectName\Area"
    }
    Write-Verbose "[Get-AzDoAreaNodes] Comparison result: $($currentList | Out-String)"

    # Determine actions based on Ensure parameter
    if ($Ensure -eq [Ensure]::Absent) {
        # Identify items present in both lists for removal
        $toRemove = ($currentList | Where-Object {
            ($_.SideIndicator -eq '==')
        }).InputObject
        Write-Verbose "[Get-AzDoAreaNodes] Items to delete: $($toRemove | Out-String)"
    } else {
        # Identify items missing in current or desired state
        $toAdd = ($currentList | Where-Object { $_.SideIndicator -eq '<=' }).InputObject
        $toRemove = ($currentList | Where-Object { $_.SideIndicator -eq '=>' }).InputObject
        Write-Verbose "[Get-AzDoAreaNodes] Items to add: $($toAdd | Out-String)"
        Write-Verbose "[Get-AzDoAreaNodes] Items to delete: $($toRemove | Out-String)"
    }

    # Update status based on differences between current and desired states
    if (($toRemove.count -ne 0) -and ($toAdd.count -ne 0)) {
        $getAreaResult.status = [DSCGetSummaryState]::Changed
        Write-Verbose "[Get-AzDoAreaNodes] Status changed: Both additions and deletions detected"
    }
    elseif ($toRemove.count -ne 0) {
        $getAreaResult.status = [DSCGetSummaryState]::Missing
        Write-Verbose "[Get-AzDoAreaNodes] Status missing: Deletions detected"
    }
    elseif ($toAdd.count -ne 0) {
        $getAreaResult.status = [DSCGetSummaryState]::NotFound
        Write-Verbose "[Get-AzDoAreaNodes] Status not found: Additions detected"
    }

    # Update propertiesChanged with determined additions and deletions
    $getAreaResult.propertiesChanged = @{
        toRemove = $toRemove | ForEach-Object { @{ Path = $_ } }
        toAdd = $toAdd | ForEach-Object { @{ Path = $_ } }
    }

    # Return the result object with all computed information
    Write-Verbose "[Get-AzDoAreaNodes] Final result: $($getAreaResult | Out-String)"
    return $getAreaResult
}
