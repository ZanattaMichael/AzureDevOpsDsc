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
    $projectAreaId = ($LookupResult.cachedAreaNodes | Where-Object { $_.path -eq "\$ProjectName\Area" }).id

    Write-Verbose "[Set-AzDoAreaNodes] Retrieved top-level area node for Project: $ProjectName."
    Write-Verbose "[Set-AzDoAreaNodes] Project ID: $($projectAreaId)"

    # If the ProjectAreaId is missing, log an error and stop.
    if ($null -eq $projectAreaId) {
        Write-Error "[Set-AzDoAreaNodes] Stopping. Cannot Enumerate ProjectAreaId for \$ProjectName\Area"
        return
    }

    # If there are properties to add, call New-AzDoIterationNodes
    # If there are properties to remove, call Remove-AzDoIterationNodes
    if ($LookupResult.propertiesChanged.toAdd.count -ne 0) {
        # Call New-AzDoIterationNodes
        New-AzDoAreaNodes @PSBoundParameters
    }
    if ($LookupResult.propertiesChanged.toRemove.count -ne 0) {
        # Call Remove-AzDoIterationNodes
        Remove-AzDoAreaNodes @PSBoundParameters
    }

    Write-Verbose "[Set-AzDoAreaNodes] Function execution completed for Project: $ProjectName."
}
