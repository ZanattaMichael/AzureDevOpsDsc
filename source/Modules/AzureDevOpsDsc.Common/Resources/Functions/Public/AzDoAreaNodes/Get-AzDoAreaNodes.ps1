Function Get-AzDoAreaNodes {
    [CmdletBinding()]
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

    Write-Verbose "[Get-AzDoAreaNodes] Start function execution"
    Write-Verbose "[Get-AzDoAreaNodes] ProjectName: $ProjectName"
    Write-Verbose "[Get-AzDoAreaNodes] AreaPaths: $($AreaPaths | Out-String)"
    # Format the Area Paths
    $AreaPaths = $AreaPaths | Format-AzDoAreaPath -ProjectName $ProjectName
    Write-Verbose "[Get-AzDoAreaNodes] FormattedAreaPaths $($AreaPaths | Out-String)"

    $OrganizationName = $Global:DSCAZDO_OrganizationName

    # Initialize the result object
    $getAreaResult = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @{
            toAdd = @()
            toRemove = @()
        }
        ProjectName = $ProjectName
        AreaPath = $AreaPaths
        Status = [DSCGetSummaryState]::Unchanged
        Reason = $null
        CachedAreaNodes = $null
    }



    # Retrieve the cached Area Nodes
    $cachedAreaNodes = Get-CacheObject -CacheType 'LiveAreaNodes' | Where-Object { $_.Key -like "\$ProjectName\Area*" }
    $cachedAreaNodes | Export-CLIXML C:\Temp\Cache.clixml
    # Set the cachedAreaNodes to the result object. This will be needed for other functions.
    $getAreaResult.cachedAreaNodes = $cachedAreaNodes

    $isTopLevel = $cachedAreaNodes | Where-Object { $_.Key -eq "\$ProjectName\Area" }

    # If the AreaPaths is count is 0, and the cachedAreaNodes is 1, but it's the top level, then the Area Node does not exist.
    # Set to unchanged and return.
    if ($AreaPaths.Count -eq 0 -and $cachedAreaNodes.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoAreaNodes] AreaPaths is not specified and no Area Nodes exist in cache"

        $getAreaResult.status = [DSCGetSummaryState]::Unchanged
        $getAreaResult.reason = 'Area Node does not exist and only the top level Area Node exists'

        return $getAreaResult
    }

    # If the $AreaPaths.Count -eq 0, then the Area Node does not exist. Set to missing and return.
    if ($AreaPaths.Count -eq 0) {
        Write-Verbose "[Get-AzDoAreaNodes] AreaPaths is not specified"

        $getAreaResult.status = [DSCGetSummaryState]::Missing
        $getAreaResult.reason = 'Area Node does not exist'

        return $getAreaResult
    }

    # If the $cachedAreaNodes.Count -eq 1 and it's the top level, then the Area Node does not exist. Set to NotFound and return.
    if ($cachedAreaNodes.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoAreaNodes] Area Node does not exist"

        $getAreaResult.status = [DSCGetSummaryState]::NotFound
        $getAreaResult.reason = 'Area Node does not exist'

        return $getAreaResult
    }

    # Compare the AreaPaths to the cachedAreaNodes.Name
    $differenceObject = $cachedAreaNodes | ForEach-Object { $_.Value.path }

    @{
        ReferenceObject = $AreaPaths
        DifferenceObject = $differenceObject
    } | Export-CLIXML C:\Temp\compare.clixml

    # Compare the two lists. Exclude the top-level areas
    $currentList = Compare-Object -ReferenceObject $AreaPaths -DifferenceObject $differenceObject -IncludeEqual | Where-Object {
        $_.InputObject -ne "\$ProjectName\Area"
    }

    $currentList | Export-Clixml C:\Temp\currentList.clixml
    $ensure | Export-CLixml C:\Temp\ensure.clixml

    # If the Ensure is Absent, then remove the Area Nodes
    if ($Ensure -eq [Ensure]::Absent) {
        # If Absent was specified, test to see if the items already exist. If so, remove them.

        # Items flagged on the right side are items that are missing in the desired state.
        $toDelete = ($currentList | Where-Object {
            ($_.SideIndicator -eq '==')
        }).InputObject

    } else {
        # Use the standard Side Indicators

        # Items flagged on the left side are items that are missing in the current state.
        $toAdd = ($currentList | Where-Object { $_.SideIndicator -eq '<=' }).InputObject
        # Items flagged on the right side are items that are missing in the desired state.
        $toDelete = ($currentList | Where-Object { $_.SideIndicator -eq '=>' }).InputObject

        $toAdd | Export-CLixml 'C:\Temp\toAdd1.clixml'
        $toDelete | Export-Clixml 'C:\Temp\toDelete1.clixml'
    }

    # If $toDelete and $toAdd is not empty, set the Ensure property to Present.
    if (($toDelete.count -ne 0) -and ($toAdd.count -ne 0)) {
        $getAreaResult.status = [DSCGetSummaryState]::Changed
    }
    # If $toDelete is not empty, set the status to NotFound
    elseif ($toDelete.count -ne 0) {
        $getAreaResult.status = [DSCGetSummaryState]::Missing
    }
    # If $toAdd is not empty, set the status to Missing
    elseif ($toAdd.count -ne 0) {
        $getAreaResult.status = [DSCGetSummaryState]::NotFound
    }

    $toAdd | Export-CLixml 'C:\Temp\toAdd.clixml'
    $toDelete | Export-Clixml 'C:\Temp\toDelete.clixml'

    # If the Ensure property is set to Present, set the Ensure property to Present.
    $getAreaResult.propertiesChanged = @{
        toDelete = ($cachedAreaNodes | Where-Object { $_.value.path -in $toDelete }).Value
        toAdd = $toAdd
    }

    return $getAreaResult

}
