Function Get-AzDoAreaNode {
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

    Write-Verbose "[Get-AzDoAreaNode] Start function execution"

    $OrganizationName = $Global:DSCAZDO_OrganizationName

    # Initialize the result object
    $getAreaResult = @{
        Ensure = [Ensure]::Absent
        propertiesChanged = @{
            toAdd = @()
            toRemove = @()
        }
        project = $ProjectName
        areaPath = $AreaPath
        status = [DSCGetSummaryState]::Unchanged
        reason = $null
        cachedAreaNodes = $null
    }

    # Retrive the cached Area Nodes
    $cachedAreaNodes = Get-CacheObject -CacheType 'LiveAreaNodes' | Where-Object { $_.Key -like "\$ProjectName\Area*" }
    # Set the cachedAreaNodes to the result object. This will be needed for other functions.
    $getAreaResult.cachedAreaNodes = $cachedAreaNodes

    $isTopLevel = $cachedAreaNodes | Where-Object { $_.Key -eq "\$ProjectName\Area" }

    # If the AreaPath is count is 0, and the cachedAreaNodes is 1, but it's the top level, then the Area Node does not exist.
    # Set to unchanged and return.
    if ($AreaPath.Count -eq 0 -and $cachedAreaNodes.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoAreaNode] AreaPath is not specified and no Area Nodes exist in cache"

        $getAreaResult.status = [DSCGetSummaryState]::Unchanged
        $getAreaResult.reason = 'Area Node does not exist and only the top level Area Node exists'

        return $getAreaResult

    }

    # If the $AreaPath.Count -eq 0, then the Area Node does not exist. Set to missing and return.
    if ($AreaPath.Count -eq 0) {
        Write-Verbose "[Get-AzDoAreaNode] AreaPath is not specified"

        $getAreaResult.status = [DSCGetSummaryState]::Missing
        $getAreaResult.reason = 'Area Node does not exist'

        return $getAreaResult
    }

    # If the $cachedAreaNodes.Count -eq 1 and it's the top level, then the Area Node does not exist. Set to NotFound and return.
    if ($cachedAreaNodes.Count -eq 1 -and $isTopLevel) {
        Write-Verbose "[Get-AzDoAreaNode] Area Node does not exist"

        $getAreaResult.status = [DSCGetSummaryState]::NotFound
        $getAreaResult.reason = 'Area Node does not exist'

        return $getAreaResult
    }

    # Compare the AreaPaths to the cachedAreaNodes.Name
    $differenceObject = $cachedAreaNodes | ForEach-Object { $_.Value.Name }
    $currentList = Compare-Object -ReferenceObject $AreaPaths -DifferenceObject $differenceObject -IncludeEqual

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
    }

    # If $toDelete and $toAdd is not empty, set the Ensure property to Present.
    if (($toDelete.count -ne 0) -and ($toAdd.count -ne 0)) {
        $Result.status = [DSCGetSummaryState]::Changed
    }
    # If $toDelete is not empty, set the status to NotFound
    elseif ($toDelete.count -ne 0) {
        $Result.status = [DSCGetSummaryState]::Missing
    }
    # If $toAdd is not empty, set the status to Missing
    elseif ($toAdd.count -ne 0) {
        $Result.status = [DSCGetSummaryState]::NotFound
    }

    # If the Ensure property is set to Present, set the Ensure property to Present.
    $getAreaResult.propertiesChanged = @{
        toDelete = $currentList | Where-Object { $_.name -in $cachedAreaNodes.value.name }
        toAdd = $toAdd
    }

    Write-Verbose "[Get-AzDoAreaNode] End function execution"
    return $getAreaResult
}
